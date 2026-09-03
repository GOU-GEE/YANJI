import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:yanji/sync/oplog/operation.dart';

import 'device_harness.dart';
import 'simulated_transport.dart';

class ScenarioResult {
  ScenarioResult(this.fingerprint, this.metrics, this.trace);
  final String fingerprint;
  final Map<String, Object?> metrics;
  final List<String> trace;
}

/// All scheduling, entity choices and wall-clock perturbations use this seed.
/// Device op IDs derive from persistent origin sequence, never system time.
class RandomScenario {
  RandomScenario(this.seed, this.actionCount);
  final int seed, actionCount;
  late DeviceCluster cluster;
  late SimulatedTransport net;
  late Random random;
  late ScenarioLog log;
  int nextEntity = 1000;
  final counts = <String, int>{};
  final revoked = <int>{};
  void count(String event) =>
      counts.update(event, (v) => v + 1, ifAbsent: () => 1);
  T pick<T>(List<T> values) => values[random.nextInt(values.length)];

  Future<ScenarioResult> run() async {
    random = Random(seed);
    log = ScenarioLog(seed);
    final timer = Stopwatch()..start();
    cluster = await DeviceCluster.create(cKnowsBProof: false);
    net = SimulatedTransport(cluster, random, log);
    try {
      log.add('BEGIN seed=$seed actions=$actionCount');
      await initializeCluster(cluster, net);
      // Real pending authorization, remote receive and restart in every seed.
      await write(cluster.b, 'task', baseTask, 'update', {
        'title': 'pending B proof',
      });
      await net.sync(1, 2);
      await net.deliverAll();
      await restart(2);
      await policyGrant();
      await net.converge();
      // Ensure all three origins have legitimate retained history before random
      // cutoffs; sparse revoked tails are intentionally NOT copied to all peers.
      await write(cluster.c, 'task', baseTask, 'update', {
        'estimated_seconds': 61,
      });
      await net.converge();
      for (var step = 0; step < actionCount; step++) {
        final device = cluster.devices[random.nextInt(3)];
        device.wall = 2000000 + step * 10 + random.nextInt(2000) - 1000;
        final roll = random.nextInt(100);
        log.add(
          'WORKLOAD step=$step device=${device.name} roll=$roll wall=${device.wall}',
        );
        if (roll >= 85 && roll < 95) {
          await networkEvent();
        } else if (roll >= 95) {
          await administrativeEvent(device);
        } else if (revoked.contains(device.index)) {
          // A disconnected revoked device may still legitimately believe it is
          // active; let its own local policy, not global scheduler knowledge, decide.
          final policy = await device.lookup(
            workspace,
            device.identity.deviceId,
          );
          if (policy?.cutoff == null) {
            await businessEvent(device, roll);
          } else {
            count('revoked_local_block');
            log.add('${device.name} local policy forbids write');
            await networkEvent();
          }
        } else {
          await businessEvent(device, roll);
        }
        // Check actual production rows during partial propagation as well as at end.
        if (step % 20 == 0) {
          for (final d in cluster.devices) {
            await d.invariantCheck();
          }
        }
      }
      log.add('STOP new operations; CONVERGENCE');
      await net.converge();
      await cluster.assertConverged(rebuild: false);
      final rebuild = <String, int>{},
          digest = <String, int>{},
          sizes = <String, int>{};
      for (final d in cluster.devices) {
        final before = await d.snapshot();
        final hash = await d.digest();
        final sw = Stopwatch()..start();
        await d.applier.rebuildWorkspace(workspace);
        rebuild[d.name] = sw.elapsedMicroseconds;
        sw.reset();
        final afterHash = await d.digest();
        digest[d.name] = sw.elapsedMicroseconds;
        if (afterHash != hash ||
            canonical(await d.snapshot()) != canonical(before)) {
          throw StateError('${d.name} rebuild changed state');
        }
        sizes[d.name] = await File(d.databasePath).length();
        final wal = File('${d.databasePath}-wal');
        if (await wal.exists()) sizes['${d.name}_wal'] = await wal.length();
      }
      await cluster.assertConverged(rebuild: false);
      final signed =
          (await cluster.a.exportAvailableOperations())
              .map(
                (p) => {
                  'key': p.key,
                  'bytes': p.operation.envelopeBytes,
                  'signature': p.operation.signature,
                },
              )
              .toList()
            ..sort(
              (a, b) => (a['key']! as String).compareTo(b['key']! as String),
            );
      final hash = await Sha256().hash(
        utf8.encode(
          canonical({
            'trace': log.actions,
            'snapshot': await cluster.a.snapshot(),
            'signed': signed,
          }),
        ),
      );
      final fingerprint = hash.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final metrics = <String, Object?>{
        'seed': seed,
        'actions': actionCount,
        'duration_ms': timer.elapsedMilliseconds,
        'authorized_operations':
            (await cluster.a.exportAvailableOperations()).length,
        'stored_op_counts': {
          for (final d in cluster.devices)
            d.name: (await d.rows('oplog')).length,
        },
        'apply_count': {for (final d in cluster.devices) d.name: d.applyCount},
        'apply_total_us': {
          for (final d in cluster.devices) d.name: d.applyMicros,
        },
        'rebuild_us': rebuild,
        'digest_us': digest,
        'sqlite_bytes': sizes,
        'event_counts': counts,
        'delivered': net.delivered,
        'dropped_attempts': net.dropped,
        'duplicated': net.duplicated,
        'fingerprint': fingerprint,
      };
      return ScenarioResult(fingerprint, metrics, List.of(log.actions));
    } catch (error, stack) {
      final dir = Directory(
        '${Platform.environment['YANJI_ARTIFACT_DIR'] ?? '.dart_tool/convergence'}/failures',
      );
      await dir.create(recursive: true);
      final file = File('${dir.path}/seed_${seed}_actions_$actionCount.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(
          normalized({
            'seed': seed,
            'actions': actionCount,
            'error': '$error',
            'stack': '$stack',
            'trace': log.actions,
            'devices': {
              for (final d in cluster.devices)
                d.name: {
                  'snapshot': await d.snapshot(),
                  'pending': await d.pendingState(),
                  'frontier': await d.frontier(),
                },
            },
          }),
        ),
      );
      Error.throwWithStackTrace(
        StateError(
          '$error\n${log.report()}\nFull trace: ${file.absolute.path}',
        ),
        stack,
      );
    } finally {
      await cluster.close();
    }
  }

  Future<void> write(
    TestDevice d,
    String type,
    String id,
    String action,
    Map<String, Object?> payload,
  ) async {
    log.add('${d.name} $type/$id $action ${canonical(payload)}');
    count('$type.$action');
    final op = await d.execute(type, id, action, payload);
    log.add('COMMIT ${d.name}#${op.parse().originSeq} ${op.parse().opId}');
    // Enqueue even when partitioned; delivery eligibility belongs to transport.
    final peers = [0, 1, 2]..remove(d.index);
    net.enqueue(d.index, pick(peers), WirePacket.fromOperation(op));
  }

  Future<void> restart(int index) async {
    log.add('restart ${String.fromCharCode(65 + index)}');
    count('restart');
    await cluster.restart(index);
  }

  Future<void> policyGrant() async {
    log.add('A fixture policy grant B');
    count('authorization_grant');
    final packet = await cluster.a.policy(deviceId(1));
    net.enqueue(0, 1, packet);
  }

  Future<void> administrativeEvent(TestDevice d) async {
    final event = random.nextInt(4);
    if (event == 0) {
      await restart(d.index);
      return;
    }
    if (event == 1) {
      final choices = [1, 2].where((i) => !revoked.contains(i)).toList();
      if (choices.isNotEmpty) {
        final target = pick(choices);
        final n = await cluster.devices[target].nextSeq();
        final cutoff = max(1, n - 1 - random.nextInt(4));
        log.add(
          'A fixture revoke ${String.fromCharCode(65 + target)} cutoff=$cutoff',
        );
        count('revoke');
        final packet = await cluster.a.policy(deviceId(target), cutoff: cutoff);
        revoked.add(target);
        net.enqueue(0, pick([1, 2]), packet);
        return;
      }
    }
    if (event == 2) {
      final policy = await d.lookup(workspace, d.identity.deviceId);
      if (policy?.cutoff == null) {
        log.add('${d.name} signed future schema');
        count('future_schema');
        final op = await d.futureOperation();
        net.enqueue(d.index, (d.index + 1) % 3, WirePacket.fromOperation(op));
        return;
      }
    }
    final packets = await d.exportAvailableOperations();
    if (packets.isNotEmpty) {
      final p = pick(packets);
      // Keep routing, mutate the signature so parsing cannot accidentally route
      // this diagnostic fixture to the test policy decoder.
      final signature = Uint8List.fromList(p.operation.signature);
      signature[0] ^= 1;
      if (p.workspaceId != workspace) return;
      log.add('tampered signature → ${d.name} ${p.key}');
      count('bad_signature');
      await d.receive(
        WirePacket(
          Operation(
            envelopeBytes: p.operation.envelopeBytes,
            signature: signature,
          ),
          p.workspaceId,
          p.origin,
          p.seq,
        ),
        from: 'corrupt fixture',
      );
    }
  }

  Future<void> businessEvent(TestDevice d, int roll) async {
    if (roll < 25) {
      final tasks = await d.rows('tasks');
      if (tasks.isEmpty || random.nextInt(4) == 0) {
        final subjects = await d.rows('subjects');
        await write(d, 'task', uid(nextEntity++), 'create', {
          'title': '${d.name} new ${log.step}',
          if (subjects.isNotEmpty) 'subject_id': pick(subjects)['id'],
        });
      } else {
        final row = random.nextBool() ? tasks.first : pick(tasks);
        final payload = random.nextBool()
            ? <String, Object?>{'title': '${d.name} edit ${log.step}'}
            : <String, Object?>{'estimated_seconds': random.nextInt(300)};
        await write(d, 'task', row['id'] as String, 'update', payload);
      }
    } else if (roll < 40) {
      final subjects = await d.rows('subjects');
      if (subjects.isEmpty || random.nextInt(4) == 0) {
        await write(d, 'subject', uid(nextEntity++), 'create', {
          'name': '${d.name} subject ${log.step}',
        });
      } else {
        await write(d, 'subject', pick(subjects)['id'] as String, 'update', {
          'name': '${d.name} subject edit ${log.step}',
        });
      }
    } else if (roll < 55) {
      await write(d, 'daily_review', reviewId, 'update', {
        'content': random.nextInt(7) == 0 ? '' : '${d.name} review ${log.step}',
      });
    } else if (roll < 75) {
      final owned = (await d.rows('study_sessions'))
          .where(
            (r) =>
                r['owner_device_id'] == d.identity.deviceId &&
                r['status'] != 'completed',
          )
          .toList();
      if (owned.isEmpty || random.nextInt(3) == 0) {
        final subjects = await d.rows('subjects');
        if (subjects.isEmpty) return;
        final tasks = await d.rows('tasks');
        await write(d, 'study_session', uid(nextEntity++), 'session.start', {
          'owner_device_id': d.identity.deviceId,
          'subject_id': pick(subjects)['id'],
          if (tasks.isNotEmpty && random.nextBool())
            'task_id': pick(tasks)['id'],
          'segment_id': uid(nextEntity++),
          'started_at_ms': log.step * 10000,
          'mode': random.nextBool() ? 'stopwatch' : 'pomodoro',
        });
      } else {
        final session = pick(owned);
        final segments =
            (await d.rows('study_session_segments'))
                .where((r) => r['session_id'] == session['id'])
                .toList()
              ..sort(
                (a, b) => (a['started_at_ms'] as int).compareTo(
                  b['started_at_ms'] as int,
                ),
              );
        final segment = segments.last;
        if (session['status'] == 'paused' && random.nextBool()) {
          await write(
            d,
            'study_session',
            session['id'] as String,
            'session.resume',
            {
              'segment_id': uid(nextEntity++),
              'started_at_ms': log.step * 10000,
            },
          );
        } else {
          final action = session['status'] == 'paused' || random.nextBool()
              ? 'session.stop'
              : 'session.pause';
          await write(d, 'study_session', session['id'] as String, action, {
            'segment_id': segment['id'],
            'ended_at_ms': session['status'] == 'paused'
                ? segment['ended_at_ms']
                : log.step * 10000,
          });
        }
      }
    } else {
      final type = pick(['task', 'subject', 'study_session']);
      final table = {
        'task': 'tasks',
        'subject': 'subjects',
        'study_session': 'study_sessions',
      }[type]!;
      final candidates = (await d.rows(table))
          .where(
            (r) =>
                r['id'] != baseTask &&
                r['id'] != baseSubject &&
                (type != 'study_session' ||
                    r['owner_device_id'] == d.identity.deviceId),
          )
          .toList();
      if (candidates.isNotEmpty) {
        await write(d, type, pick(candidates)['id'] as String, 'delete', {});
      } else {
        count('delete_no_candidate');
        log.add('${d.name} delete: no eligible entity');
      }
    }
  }

  Future<void> networkEvent() async {
    final event = random.nextInt(13);
    count('network_$event');
    log.add('NETWORK event=$event');
    switch (event) {
      case 0:
        await net.deliverNext();
      case 1:
        for (var i = 0, n = 1 + random.nextInt(8); i < n; i++) {
          await net.deliverRandom();
        }
      case 2:
        net.duplicate();
      case 3:
        net.partition(0, 1);
      case 4:
        net.partition(0, 2);
      case 5:
        net.partition(1, 2);
      case 6:
        net.fullPartition();
      case 7:
        final pair = pick([(0, 1), (0, 2), (1, 2)]);
        net.healLink(pair.$1, pair.$2);
      case 8:
        net.healPartition();
      case 9:
        await restart(random.nextInt(3));
      case 10:
        net.delay();
      case 11:
        net.dropDeliveryAttempt();
      case 12:
        for (final pair in net.queues.keys) {
          await net.sync(pair.$1, pair.$2);
        }
    }
  }
}
