import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/clock/hlc.dart';

void main() {
  test(
    'local events remain increasing when physical time repeats or rolls back',
    () {
      final first = Hlc.tick(nowMs: 1000);
      final next = Hlc.tick(nowMs: 1000, previous: first);
      final rollback = Hlc.tick(nowMs: 900, previous: next);
      expect(first, Hlc(1000, 0));
      expect(next, Hlc(1000, 1));
      expect(rollback, Hlc(1000, 2));
      expect(Hlc.tick(nowMs: 1100, previous: rollback), Hlc(1100, 0));
    },
  );

  test('receive handles every maximum-wall branch', () {
    expect(
      Hlc.receive(nowMs: 1, local: Hlc(10, 2), remote: Hlc(10, 8)),
      Hlc(10, 9),
    );
    expect(
      Hlc.receive(nowMs: 1, local: Hlc(20, 2), remote: Hlc(10, 8)),
      Hlc(20, 3),
    );
    expect(
      Hlc.receive(nowMs: 1, local: Hlc(10, 2), remote: Hlc(20, 8)),
      Hlc(20, 9),
    );
    expect(
      Hlc.receive(nowMs: 30, local: Hlc(10, 2), remote: Hlc(20, 8)),
      Hlc(30, 0),
    );
  });

  test('random receive transitions are after both causal inputs', () {
    final random = Random(20260903);
    for (var i = 0; i < 2000; i++) {
      final local = Hlc(random.nextInt(100), random.nextInt(100));
      final remote = Hlc(random.nextInt(100), random.nextInt(100));
      final result = Hlc.receive(
        nowMs: random.nextInt(100),
        local: local,
        remote: remote,
      );
      expect(result.compareTo(local), greaterThan(0));
      expect(result.compareTo(remote), greaterThan(0));
    }
  });

  test('equal clocks resolve by device ID consistently', () {
    final clock = Hlc(10, 1);
    expect(
      clock.compareEvent(clock, deviceId: 'a', otherDeviceId: 'b'),
      lessThan(0),
    );
    expect(
      clock.compareEvent(clock, deviceId: 'b', otherDeviceId: 'a'),
      greaterThan(0),
    );
  });

  test('invalid input and counter overflow fail instead of wrapping', () {
    expect(() => Hlc(-1, 0), throwsArgumentError);
    expect(() => Hlc(1, -1), throwsArgumentError);
    expect(() => Hlc.tick(nowMs: -1), throwsArgumentError);
    expect(
      () => Hlc.tick(nowMs: 0, previous: Hlc(0, 0x7fffffffffffffff)),
      throwsStateError,
    );
  });
}
