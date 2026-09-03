import 'dart:math' as math;

/// HLC only orders events. It does not measure study time or prove concurrency.
/// The writer must persist the returned value in the same transaction as its op.
final class Hlc implements Comparable<Hlc> {
  Hlc(this.wallMs, this.counter) {
    if (wallMs < 0 || counter < 0) {
      throw ArgumentError('HLC components must be non-negative');
    }
  }

  final int wallMs;
  final int counter;

  static int _increment(int value) {
    if (value == 0x7fffffffffffffff) {
      throw StateError('HLC counter exhausted');
    }
    return value + 1;
  }

  /// Pure transition: rolling back a transaction must not advance shared state.
  static Hlc tick({required int nowMs, Hlc? previous}) {
    if (nowMs < 0) throw ArgumentError.value(nowMs, 'nowMs');
    if (previous == null || nowMs > previous.wallMs) return Hlc(nowMs, 0);
    return Hlc(previous.wallMs, _increment(previous.counter));
  }

  /// Receive transition preserves causality despite clock skew or rollback.
  static Hlc receive({
    required int nowMs,
    required Hlc local,
    required Hlc remote,
  }) {
    if (nowMs < 0) throw ArgumentError.value(nowMs, 'nowMs');
    final wall = math.max(nowMs, math.max(local.wallMs, remote.wallMs));
    final int counter;
    if (wall == local.wallMs && wall == remote.wallMs) {
      counter = _increment(math.max(local.counter, remote.counter));
    } else if (wall == local.wallMs) {
      counter = _increment(local.counter);
    } else if (wall == remote.wallMs) {
      counter = _increment(remote.counter);
    } else {
      counter = 0;
    }
    return Hlc(wall, counter);
  }

  @override
  int compareTo(Hlc other) {
    final wall = wallMs.compareTo(other.wallMs);
    return wall != 0 ? wall : counter.compareTo(other.counter);
  }

  /// SYNC.md's final deterministic tie-breaker; device IDs are ASCII UUIDs.
  int compareEvent(
    Hlc other, {
    required String deviceId,
    required String otherDeviceId,
  }) {
    final clock = compareTo(other);
    return clock != 0 ? clock : deviceId.compareTo(otherDeviceId);
  }

  @override
  bool operator ==(Object other) =>
      other is Hlc && wallMs == other.wallMs && counter == other.counter;

  @override
  int get hashCode => Object.hash(wallMs, counter);

  @override
  String toString() => '$wallMs/$counter';
}
