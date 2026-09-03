import 'package:cryptography/cryptography.dart';

import '../oplog/operation.dart';
import '../protocol/deterministic_cbor.dart';

/// Retain exactly the causally maximal versions of one field. Calling this on
/// all currently valid operations also handles late arrival and revocation.
final class MultiValueRegister {
  static List<OperationEnvelope> versions(
    Iterable<OperationEnvelope> history,
    String field,
  ) {
    final writes = history
        .where(
          (op) =>
              op.payload is Map<String, Object?> &&
              (op.payload! as Map<String, Object?>).containsKey(field),
        )
        .toList();
    if (writes.isEmpty) return [];
    final first = writes.first;
    if (writes.any(
      (op) =>
          op.workspaceId != first.workspaceId ||
          op.entityType != first.entityType ||
          op.entityId != first.entityId,
    )) {
      throw ArgumentError(
        'Register must describe a single workspace/entity/field',
      );
    }
    final maxima =
        writes
            .where((op) => !writes.any((other) => op.happensBefore(other)))
            .toList()
          ..sort((a, b) => a.opId.compareTo(b.opId));
    return List.unmodifiable(maxima);
  }

  static OperationEnvelope winner(List<OperationEnvelope> versions) {
    if (versions.isEmpty) throw StateError('Empty register');
    return versions.reduce((a, b) => a.compareWinner(b) > 0 ? a : b);
  }

  static Future<String> conflictId(
    List<OperationEnvelope> versions,
    String field,
  ) async {
    if (versions.length < 2) throw ArgumentError('Not a conflict');
    final first = versions.first;
    if (versions.any(
      (op) =>
          op.workspaceId != first.workspaceId ||
          op.entityType != first.entityType ||
          op.entityId != first.entityId,
    )) {
      throw ArgumentError('Mixed conflict');
    }
    final ids = versions.map((op) => op.opId).toSet().toList()..sort();
    final hash = await Sha256().hash(
      DeterministicCbor.encode([
        first.workspaceId,
        first.entityType,
        first.entityId,
        field,
        ids,
      ]),
    );
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
