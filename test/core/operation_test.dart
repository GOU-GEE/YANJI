import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/clock/hlc.dart';
import 'package:yanji/sync/oplog/operation.dart';

OperationEnvelope envelope({
  Map<String, Object?>? payload,
  Map<String, int>? context,
  String origin = 'a',
  int seq = 1,
  String workspace = 'w',
}) => OperationEnvelope(
  opId: '$origin-$seq',
  workspaceId: workspace,
  originDeviceId: origin,
  originSeq: seq,
  hlc: Hlc(100, seq),
  causalContext: context ?? {if (seq > 1) origin: seq - 1},
  entityType: 'task',
  entityId: 't',
  action: 'create',
  payloadSchemaVersion: 1,
  payload: payload ?? {'title': 'task'},
);
void main() {
  test(
    'nested payload, causal context, and signed bytes are immutable copies',
    () {
      final data = Uint8List.fromList([1, 2]);
      final list = <Object?>['original'];
      final context = <String, int>{'b': 2};
      final e = envelope(
        payload: {'bytes': data, 'nested': list},
        context: context,
      );
      data[0] = 9;
      list[0] = 'changed';
      context['b'] = 99;
      final payload = e.payload! as Map<String, Object?>;
      expect(payload['bytes'], [1, 2]);
      expect(payload['nested'], ['original']);
      expect(e.causalContext['b'], 2);
      expect(
        () => (payload['bytes'] as Uint8List)[0] = 8,
        throwsUnsupportedError,
      );
      expect(
        () => (payload['nested'] as List<Object?>)[0] = 'x',
        throwsUnsupportedError,
      );
      final bytes = Uint8List.fromList(e.bytes), signature = Uint8List(64);
      final op = Operation(envelopeBytes: bytes, signature: signature);
      bytes[0] = 0;
      signature[0] = 8;
      expect(op.envelopeBytes, e.bytes);
      expect(op.signature[0], 0);
      expect(() => op.envelopeBytes[0] = 0, throwsUnsupportedError);
    },
  );
  test('causality uses workspace/dot/context, not HLC order', () {
    final a = envelope(), a2 = envelope(seq: 2), b = envelope(origin: 'b');
    expect(a.happensBefore(a2), true);
    expect(a.concurrentWith(b), true);
    final seen = envelope(origin: 'b', context: {'a': 1});
    expect(a.happensBefore(seen), true);
    expect(
      () => a.happensBefore(envelope(workspace: 'other')),
      throwsArgumentError,
    );
    expect(() => envelope(context: {'a': 1}), throwsFormatException);
  });
}
