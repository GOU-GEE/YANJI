import 'package:drift/drift.dart';

import '../core/crypto/device_identity.dart';
import '../core/database/app_database.dart';
import '../core/ids/entity_ids.dart';
import '../domain/business_schema.dart';
import 'oplog/operation.dart';
import 'oplog/operation_journal.dart';
import 'projection/projection_store.dart';
import 'protocol/deterministic_cbor.dart';

final class BusinessCommand {
  BusinessCommand({
    required this.workspaceId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required Map<String, Object?> payload,
  }) : payload =
           DeterministicCbor.decode(DeterministicCbor.encode(payload))!
               as Map<String, Object?>;
  final String workspaceId, entityType, entityId, action;
  final Map<String, Object?> payload;
}

/// Public receive boundary. Verification, persisted signed history, clocks,
/// authorization changes and real SQL materialization share one outer transaction.
final class OperationApplier {
  OperationApplier(
    this.database,
    DeviceIdentity identity, {
    required OriginLookup lookupOrigin,
    int Function()? nowMs,
    EntityIds? ids,
  }) : _journal = OperationJournal(
         database,
         identity,
         lookupOrigin: lookupOrigin,
         nowMs: nowMs,
         ids: ids,
         validateEnvelope: BusinessSchema.validate,
       ),
       projections = ProjectionStore(database, lookupOrigin);
  final AppDatabase database;
  int revision = 0;
  final OperationJournal _journal;
  final ProjectionStore projections;

  Future<ReceiveResult> receive(
    Operation packet, {
    required String workspaceId,
    required String originDeviceId,
    String? receivedFrom,
  }) => database
      .transaction(() async {
        final result = await _journal.receive(
          packet,
          workspaceId: workspaceId,
          originDeviceId: originDeviceId,
          receivedFrom: receivedFrom,
        );
        if (result == ReceiveResult.stored) {
          await projections.rebuildWorkspace(workspaceId);
        }
        return result;
      })
      .then((result) {
        if (result == ReceiveResult.stored ||
            result == ReceiveResult.pendingAuthorization) {
          revision++;
        }
        return result;
      });
  Future<void> refreshAuthorization(String workspace) =>
      database.transaction(() async {
        await _journal.refreshAuthorization(workspace);
        await projections.rebuildWorkspace(workspace);
      });
  Future<List<ReceiveResult>> receiveBatch(
    String workspace,
    List<Operation> packets, {
    String? receivedFrom,
  }) => database
      .transaction(() async {
        final results = <ReceiveResult>[];
        for (final packet in packets) {
          results.add(
            await _journal.receive(
              packet,
              workspaceId: workspace,
              originDeviceId: packet.parse().originDeviceId,
              receivedFrom: receivedFrom,
            ),
          );
        }
        if (results.any((r) => r == ReceiveResult.stored)) {
          await projections.rebuildWorkspace(workspace);
        }
        return results;
      })
      .then((results) {
        revision += results
            .where(
              (r) =>
                  r == ReceiveResult.stored ||
                  r == ReceiveResult.pendingAuthorization,
            )
            .length;
        return results;
      });
  Future<void> rebuildEntity(String workspace, String type, String id) =>
      database.transaction(() async {
        await _journal.refreshAuthorization(workspace);
        await projections.rebuildEntity(workspace, type, id);
      });
  Future<void> rebuildWorkspace(String workspace) =>
      database.transaction(() async {
        await _journal.refreshAuthorization(workspace);
        await projections.rebuildWorkspace(workspace);
      });
  Future<List<Operation>> export(String workspace) =>
      _journal.export(workspace);
  Future<Map<String, int>> frontier(String workspace) =>
      _journal.frontier(workspace);
  Future<Operation> appendSystem({
    required String workspaceId,
    required String entityId,
    required Map<String, Object?> payload,
  }) => database
      .transaction(() async {
        final packet = await _journal.append(
          workspaceId: workspaceId,
          entityType: 'device',
          entityId: entityId,
          action: 'system',
          payload: payload,
        );
        await projections.rebuildWorkspace(workspaceId);
        return packet;
      })
      .then((packet) {
        revision++;
        return packet;
      });
  Future<String> projectionDigest(String workspace) =>
      projections.projectionDigest(workspace);
}

/// The sole production local business-write API. This future resolves only after
/// COMMIT. Failed validation, projection or clock writes roll back every layer.
final class OperationWriter {
  OperationWriter(this.applier);
  final OperationApplier applier;
  Future<List<String>> _subjectTargets(BusinessCommand command) async {
    if (command.entityType != 'subject' || command.action == 'create') {
      return [command.entityId];
    }
    final aliases = await applier.projections.subjectAliases(
      command.workspaceId,
    );
    final canonical = aliases[command.entityId] ?? command.entityId;
    return {
      command.entityId,
      ...aliases.entries.where((e) => e.value == canonical).map((e) => e.key),
    }.toList()..sort();
  }

  Future<void> executeBatch(List<BusinessCommand> commands) => applier.database
      .transaction(() async {
        for (final command in commands) {
          for (final id in await _subjectTargets(command)) {
            await applier._journal.append(
              workspaceId: command.workspaceId,
              entityType: command.entityType,
              entityId: id,
              action: command.action,
              payload: command.payload,
            );
          }
        }
        for (final workspace in commands.map((c) => c.workspaceId).toSet()) {
          await applier.projections.rebuildWorkspace(workspace);
        }
        for (final command in commands) {
          final row = await applier.database
              .customSelect(
                'SELECT state FROM materialization_state WHERE workspace_id=? AND entity_type=? AND entity_id=?',
                variables: [
                  Variable(command.workspaceId),
                  Variable(command.entityType),
                  Variable(command.entityId),
                ],
              )
              .getSingleOrNull();
          if (row?.read<String>('state') != 'materialized') {
            throw StateError('合并记录未能完整保存，请重试');
          }
        }
      })
      .then((_) {
        applier.revision += commands.length;
      });
  Future<Operation> execute(BusinessCommand command) => applier.database
      .transaction(() async {
        if (![
          'create',
          'update',
          'delete',
          'session.start',
          'session.pause',
          'session.resume',
          'session.stop',
        ].contains(command.action)) {
          throw const FormatException('Invalid command action');
        }
        final payload = <String, Object?>{
          if (command.action == 'create')
            ...BusinessSchema.defaults[command.entityType] ?? {},
          ...command.payload,
        };
        final targets = await _subjectTargets(command);
        // Validation of relational state happens in the SAME resolver used remotely.
        final packet = await applier._journal.append(
          workspaceId: command.workspaceId,
          entityType: command.entityType,
          entityId: command.entityId,
          action: command.action,
          payload: payload,
        );
        for (final id in targets.where((id) => id != command.entityId)) {
          await applier._journal.append(
            workspaceId: command.workspaceId,
            entityType: command.entityType,
            entityId: id,
            action: command.action,
            payload: payload,
          );
        }
        await applier.projections.rebuildWorkspace(command.workspaceId);
        final state = await applier.database
            .customSelect(
              'SELECT apply_state FROM oplog WHERE op_id=?',
              variables: [Variable(packet.parse().opId)],
            )
            .getSingle();
        if (state.read<String>('apply_state') != 'applied') {
          throw StateError(
            'Command cannot materialize: ${state.read<String>('apply_state')}',
          );
        }
        final materialized = await applier.database
            .customSelect(
              'SELECT state FROM materialization_state WHERE workspace_id=? AND entity_type=? AND entity_id=?',
              variables: [
                Variable(command.workspaceId),
                Variable(command.entityType),
                Variable(command.entityId),
              ],
            )
            .getSingleOrNull();
        final expected = command.action == 'delete'
            ? 'deleted'
            : 'materialized';
        if (materialized?.read<String>('state') != expected) {
          throw StateError('Command target is not $expected');
        }
        return packet;
      })
      .then((packet) {
        applier.revision++;
        return packet;
      });
}
