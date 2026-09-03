import 'dart:typed_data';

import '../../core/clock/hlc.dart';
import '../protocol/deterministic_cbor.dart';

/// Immutable protocol envelope; canonical decoding freezes all nested values.
final class OperationEnvelope {
  OperationEnvelope({
    required String opId,
    required String workspaceId,
    required String originDeviceId,
    required int originSeq,
    required Hlc hlc,
    required Map<String, int> causalContext,
    required String entityType,
    required String entityId,
    required String action,
    required int payloadSchemaVersion,
    required Object? payload,
    int wireVersion = 1,
  }) : this.fromBytes(
         DeterministicCbor.encode({
           'wire_version': wireVersion,
           'workspace_id': workspaceId,
           'op_id': opId,
           'origin_device_id': originDeviceId,
           'origin_seq': originSeq,
           'hlc_wall_ms': hlc.wallMs,
           'hlc_counter': hlc.counter,
           'causal_context': causalContext,
           'entity_type': entityType,
           'entity_id': entityId,
           'action': action,
           'payload_schema_version': payloadSchemaVersion,
           'payload': payload,
         }),
       );

  OperationEnvelope.fromBytes(Uint8List raw)
    : bytes = Uint8List.fromList(raw).asUnmodifiableView() {
    final decoded = DeterministicCbor.decode(bytes);
    if (decoded is! Map<String, Object?> ||
        decoded.length != _fields.length ||
        !_fields.every(decoded.containsKey)) {
      throw const FormatException('Invalid envelope fields');
    }
    _fieldsMap = decoded;
    for (final field in [
      'workspace_id',
      'op_id',
      'origin_device_id',
      'entity_type',
      'entity_id',
      'action',
    ]) {
      if (decoded[field] is! String || (decoded[field] as String).isEmpty) {
        throw FormatException('Invalid $field');
      }
    }
    for (final field in [
      'wire_version',
      'origin_seq',
      'payload_schema_version',
      'hlc_wall_ms',
      'hlc_counter',
    ]) {
      final v = decoded[field];
      if (v is! int || v < (field.startsWith('hlc_') ? 0 : 1)) {
        throw FormatException('Invalid $field');
      }
    }
    if (wireVersion != 1) {
      throw const FormatException('Unsupported wire version');
    }
    final context = decoded['causal_context'];
    if (context is! Map<String, Object?>) {
      throw const FormatException('Invalid causal context');
    }
    final validated = <String, int>{};
    for (final entry in context.entries) {
      if (entry.key.isEmpty ||
          entry.value is! int ||
          (entry.value as int) < 0) {
        throw const FormatException('Invalid context entry');
      }
      validated[entry.key] = entry.value as int;
    }
    if ((validated[originDeviceId] ?? 0) != originSeq - 1) {
      throw const FormatException('Origin context must precede its dot');
    }
    causalContext = Map.unmodifiable(validated);
  }
  static const _fields = [
    'wire_version',
    'workspace_id',
    'op_id',
    'origin_device_id',
    'origin_seq',
    'hlc_wall_ms',
    'hlc_counter',
    'causal_context',
    'entity_type',
    'entity_id',
    'action',
    'payload_schema_version',
    'payload',
  ];
  final Uint8List bytes;
  late final Map<String, Object?> _fieldsMap;
  late final Map<String, int> causalContext;
  String get opId => _fieldsMap['op_id']! as String;
  String get workspaceId => _fieldsMap['workspace_id']! as String;
  String get originDeviceId => _fieldsMap['origin_device_id']! as String;
  int get originSeq => _fieldsMap['origin_seq']! as int;
  int get wireVersion => _fieldsMap['wire_version']! as int;
  int get payloadSchemaVersion => _fieldsMap['payload_schema_version']! as int;
  Hlc get hlc =>
      Hlc(_fieldsMap['hlc_wall_ms']! as int, _fieldsMap['hlc_counter']! as int);
  String get entityType => _fieldsMap['entity_type']! as String;
  String get entityId => _fieldsMap['entity_id']! as String;
  String get action => _fieldsMap['action']! as String;
  Object? get payload => _fieldsMap['payload'];
  Map<String, Object?> toMap() => _fieldsMap;

  bool happensBefore(OperationEnvelope other) {
    if (workspaceId != other.workspaceId) {
      throw ArgumentError('Different workspaces');
    }
    return originDeviceId == other.originDeviceId
        ? originSeq < other.originSeq
        : (other.causalContext[originDeviceId] ?? 0) >= originSeq;
  }

  bool concurrentWith(OperationEnvelope other) =>
      opId != other.opId && !happensBefore(other) && !other.happensBefore(this);
  int compareWinner(OperationEnvelope other) {
    final clock = hlc.compareEvent(
      other.hlc,
      deviceId: originDeviceId,
      otherDeviceId: other.originDeviceId,
    );
    return clock != 0 ? clock : opId.compareTo(other.opId);
  }
}

/// Carries the original bytes, not a reconstructed serialization for verification.
/// Merely constructing this object does not establish signature or membership.
final class Operation {
  Operation({required Uint8List envelopeBytes, required Uint8List signature})
    : envelopeBytes = Uint8List.fromList(envelopeBytes).asUnmodifiableView(),
      signature = Uint8List.fromList(signature).asUnmodifiableView() {
    if (signature.length != 64 ||
        envelopeBytes.length > DeterministicCbor.maxBytes) {
      throw const FormatException('Invalid signed packet length');
    }
  }
  final Uint8List envelopeBytes;
  final Uint8List signature;
  OperationEnvelope parse() => OperationEnvelope.fromBytes(envelopeBytes);
}
