import 'dart:math';

import 'device_harness.dart';

class ScenarioLog {
  ScenarioLog(this.seed);
  final int seed;
  final List<String> actions = [];
  int step = 0;
  void add(String action) =>
      actions.add('${(++step).toString().padLeft(5, '0')} $action');
  String report() =>
      'FAILED seed=$seed step=$step\n${actions.skip(max(0, actions.length - 200)).join('\n')}';
}

class Delivery {
  Delivery(this.from, this.to, this.packet);
  final int from, to;
  final WirePacket packet;
}

/// Opaque byte queues; never looks at entity type, action, payload or resolver.
class SimulatedTransport {
  SimulatedTransport(this.cluster, this.random, this.log);
  final DeviceCluster cluster;
  final Random random;
  final ScenarioLog log;
  final queues = <(int, int), List<Delivery>>{
    for (var a = 0; a < 3; a++)
      for (var b = 0; b < 3; b++)
        if (a != b) (a, b): [],
  };
  final blocked = <(int, int)>{};
  int delivered = 0, dropped = 0, duplicated = 0;
  String name(int i) => String.fromCharCode(65 + i);
  void enqueue(int from, int to, WirePacket packet) {
    queues[(from, to)]!.add(Delivery(from, to, packet.copy()));
    log.add('enqueue ${name(from)} → ${name(to)} ${packet.key}');
  }

  void partition(int a, int b) {
    blocked.addAll([(a, b), (b, a)]);
    log.add('NETWORK partition ${name(a)}/${name(b)}');
  }

  void fullPartition() {
    blocked.addAll(queues.keys);
    log.add('NETWORK full partition');
  }

  void healLink(int a, int b) {
    blocked.removeAll([(a, b), (b, a)]);
    log.add('NETWORK heal ${name(a)}/${name(b)}');
  }

  void healPartition() {
    blocked.clear();
    log.add('NETWORK heal all');
  }

  List<(int, int)> get available => queues.keys
      .where((k) => !blocked.contains(k) && queues[k]!.isNotEmpty)
      .toList();
  Future<bool> deliverNext({int? from, int? to}) async {
    final keys = available
        .where(
          (k) => (from == null || k.$1 == from) && (to == null || k.$2 == to),
        )
        .toList();
    if (keys.isEmpty) return false;
    return _deliver(keys.first, 0);
  }

  Future<bool> deliverRandom() async {
    final keys = available;
    if (keys.isEmpty) return false;
    final key = keys[random.nextInt(keys.length)];
    return _deliver(key, random.nextInt(queues[key]!.length));
  }

  Future<bool> _deliver((int, int) key, int index) async {
    final d = queues[key]!.removeAt(index);
    log.add('deliver ${name(d.from)} → ${name(d.to)} ${d.packet.key}');
    await cluster.devices[d.to].receive(d.packet, from: name(d.from));
    delivered++;
    return true;
  }

  Future<void> deliverAll({bool randomOrder = true, int limit = 100000}) async {
    for (var i = 0; i < limit; i++) {
      if (!await (randomOrder ? deliverRandom() : deliverNext())) return;
    }
    throw StateError('delivery upper bound exceeded\n${log.report()}');
  }

  void duplicate() {
    final keys = queues.keys.where((k) => queues[k]!.isNotEmpty).toList();
    if (keys.isEmpty) return;
    final key = keys[random.nextInt(keys.length)], list = queues[key]!;
    final d = list[random.nextInt(list.length)];
    list.add(Delivery(d.from, d.to, d.packet.copy()));
    duplicated++;
    log.add('duplicate ${name(d.from)} → ${name(d.to)} ${d.packet.key}');
  }

  void delay() {
    final keys = queues.keys.where((k) => queues[k]!.isNotEmpty).toList();
    if (keys.isEmpty) return;
    final list = queues[keys[random.nextInt(keys.length)]]!;
    final d = list.removeAt(0);
    list.add(d);
    log.add('delay ${name(d.from)} → ${name(d.to)} ${d.packet.key}');
  }

  void dropDeliveryAttempt() {
    final keys = queues.keys.where((k) => queues[k]!.isNotEmpty).toList();
    if (keys.isEmpty) return;
    final list = queues[keys[random.nextInt(keys.length)]]!;
    final d = list.removeAt(random.nextInt(list.length));
    dropped++;
    log.add('drop attempt ${name(d.from)} → ${name(d.to)} ${d.packet.key}');
  }

  /// Frontier diff plus a sparse inventory avoids resending already-stored dots
  /// above a gap. Neither receipt nor queue removal deletes source history.
  Future<int> sync(int from, int to) async {
    if (blocked.contains((from, to))) return 0;
    final peer = cluster.devices[to];
    final frontier = await peer.frontier();
    final known = (await peer.exportAvailableOperations())
        .map((p) => p.key)
        .toSet();
    final queued = queues[(from, to)]!.map((d) => d.packet.key).toSet();
    var added = 0;
    for (final packet
        in await cluster.devices[from].exportAvailableOperations()) {
      if (packet.seq > (frontier[packet.stream] ?? 0) &&
          !known.contains(packet.key) &&
          queued.add(packet.key)) {
        enqueue(from, to, packet);
        added++;
      }
    }
    return added;
  }

  Future<void> converge({int maxRounds = 20}) async {
    healPartition();
    for (var round = 0; round < maxRounds; round++) {
      await deliverAll();
      var added = 0;
      for (final key in queues.keys) {
        added += await sync(key.$1, key.$2);
      }
      log.add('convergence round=$round new=$added');
      if (added == 0) return;
    }
    final state = {
      for (final d in cluster.devices)
        d.name: {
          'frontier': await d.frontier(),
          'pending': await d.pendingState(),
        },
    };
    throw StateError(
      'convergence upper bound seed=${log.seed}: ${canonical(state)}\n${log.report()}',
    );
  }
}

Future<void> initializeCluster(DeviceCluster c, SimulatedTransport net) async {
  await c.a.execute('workspace', workspace, 'create', {
    'name': '研迹',
    'stats_timezone': 'Asia/Shanghai',
    'created_at_ms': 1,
    'created_by_device_id': deviceId(0),
  });
  await c.a.execute(
    'exam_profile',
    'exam_profile/$workspace/default',
    'create',
    {'exam_name': '考研'},
  );
  await c.a.execute('subject', baseSubject, 'create', {'name': 'Math'});
  await c.a.execute('task', baseTask, 'create', {
    'title': 'Initial',
    'estimated_seconds': 60,
    'subject_id': baseSubject,
  });
  await c.a.execute('daily_review', reviewId, 'create', {
    'review_date': '2026-09-03',
    'content': 'X',
  });
  await net.converge();
}
