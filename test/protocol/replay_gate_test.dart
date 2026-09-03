import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/clock/hlc.dart';
import 'package:yanji/sync/oplog/operation.dart';
import 'package:yanji/sync/conflict/multi_value_register.dart';

import '../support/replay_reference.dart';

OperationEnvelope op(
  String origin,
  int seq, {
  String type = 'task',
  String id = 't',
  String action = 'update',
  Map<String, Object?> payload = const {},
  Map<String, int> context = const {},
  int wall = 100,
}) => OperationEnvelope(
  opId: '$origin-$seq',
  workspaceId: 'w',
  originDeviceId: origin,
  originSeq: seq,
  hlc: Hlc(wall, seq),
  causalContext: {if (seq > 1) origin: seq - 1, ...context},
  entityType: type,
  entityId: id,
  action: action,
  payloadSchemaVersion: 1,
  payload: payload,
);
ReplayReference replica() => ReplayReference()
  ..authorize('w', 'a')
  ..authorize('w', 'b')
  ..authorize('w', 'c');
void main() {
  test(
    'update before create remains pending then materializes updated fields',
    () {
      final r = replica(),
          create = op(
            'a',
            1,
            action: 'create',
            payload: {'title': 'old', 'estimated_seconds': 60},
          ),
          update = op('a', 2, payload: {'title': 'new'});
      r.receive(update);
      expect(r.states[update.opId], 'pending_entity_create');
      expect(r.projection, isEmpty);
      r.receive(create);
      expect(r.projection[('w', 'task', 't')], {
        'title': 'new',
        'estimated_seconds': 60,
      });
    },
  );
  test('late Subject automatically retries dependent Session', () {
    final r = replica(),
        session = op(
          'a',
          1,
          type: 'study_session',
          id: 's',
          action: 'create',
          payload: {'subject_id': 'math', 'owner_device_id': 'a'},
        );
    r.receive(session);
    expect(r.states[session.opId], 'pending_dependency');
    r.receive(
      op(
        'b',
        1,
        type: 'subject',
        id: 'math',
        action: 'create',
        payload: {'name': '数学'},
      ),
    );
    expect(r.states[session.opId], 'applied');
    expect(r.projection[('w', 'study_session', 's')], isNotNull);
  });
  test(
    'authorization proof late arrival permits retry in the reference model',
    () {
      final r = ReplayReference(),
          task = op('a', 1, action: 'create', payload: {'title': 'task'});
      r.receive(task);
      expect(r.states[task.opId], 'pending_authorization');
      expect(r.projection, isEmpty);
      r.authorize('w', 'a');
      expect(r.states[task.opId], 'applied');
    },
  );
  test('concurrent review versions survive and a causally observing choice resolves both', () async {
    final a = op(
      'a',
      1,
      type: 'daily_review',
      id: 'review',
      action: 'create',
      payload: {'content': '版本A'},
    );
    final b = op(
      'b',
      1,
      type: 'daily_review',
      id: 'review',
      action: 'create',
      payload: {'content': '版本B'},
    );
    final c = op(
      'c',
      1,
      type: 'daily_review',
      id: 'review',
      payload: {'content': '合并'},
      context: {'a': 1, 'b': 1},
      wall: 101,
    );
    final r = replica()
      ..receive(b)
      ..receive(a);
    expect(
      r.textVersions[('w', 'daily_review', 'review')]!.map((v) => v.opId),
      ['a-1', 'b-1'],
    );
    final conflict = await MultiValueRegister.conflictId([a, b], 'content');
    expect(await MultiValueRegister.conflictId([b, a], 'content'), conflict);
    r.receive(c);
    expect(
      r.textVersions[('w', 'daily_review', 'review')]!.map((v) => v.opId),
      ['c-1'],
    );
    expect(r.projection[('w', 'daily_review', 'review')]!['content'], '合并');
    for (var seed = 0; seed < 30; seed++) {
      final shuffled = [a, b, c]..shuffle(Random(seed));
      final other = replica();
      for (final value in [...shuffled, ...shuffled]) {
        other.receive(value);
      }
      expect(other.projection, r.projection);
      expect(
        other.textVersions[('w', 'daily_review', 'review')]!.map((v) => v.opId),
        ['c-1'],
      );
    }
  });
  test(
    'clearing review is a causal write, then the same ID accepts new content',
    () {
      final r = replica();
      r.receive(
        op(
          'a',
          1,
          type: 'daily_review',
          id: 'review',
          action: 'create',
          payload: {'content': 'text'},
        ),
      );
      r.receive(
        op(
          'a',
          2,
          type: 'daily_review',
          id: 'review',
          payload: {'content': ''},
        ),
      );
      expect(r.projection[('w', 'daily_review', 'review')]!['content'], '');
      r.receive(
        op(
          'a',
          3,
          type: 'daily_review',
          id: 'review',
          payload: {'content': 'new'},
        ),
      );
      expect(r.projection[('w', 'daily_review', 'review')]!['content'], 'new');
    },
  );
  test('cutoff late arrival removes already-materialized update and recomputes previous value', () {
    final create = op('a', 1, action: 'create', payload: {'title': 'safe'}),
        bad = op('b', 2, payload: {'title': 'revoked'}, wall: 500);
    final early = replica()
      ..receive(create)
      ..receive(bad);
    expect(early.projection[('w', 'task', 't')]!['title'], 'revoked');
    early.revoke('w', 'b', 1);
    expect(early.states[bad.opId], 'unauthorized_revoked');
    expect(early.projection[('w', 'task', 't')]!['title'], 'safe');
    final late = replica()
      ..revoke('w', 'b', 1)
      ..receive(bad)
      ..receive(create);
    expect(early.projection, late.projection);
    early.authorize('w', 'b');
    early.revoke('w', 'b', 20);
    expect(early.cutoff[('w', 'b')], 1);
    expect(early.projection, late.projection);
  });
  test(
    'three reference replicas converge across duplicates/gossip/delete order',
    () {
      final operations = [
        op(
          'a',
          1,
          action: 'create',
          payload: {'title': 'first', 'estimated_seconds': 60},
        ),
        op('a', 2, payload: {'title': 'changed'}),
        op('b', 1, payload: {'estimated_seconds': 120}),
      ];
      final a = replica(), b = replica(), c = replica();
      for (final value in operations) {
        a.receive(value);
      }
      for (final value in operations.reversed) {
        b.receive(value);
        b.receive(value);
      }
      for (final value in b.history.values) {
        c.receive(value);
      }
      expect(a.projection, b.projection);
      expect(b.projection, c.projection);
      expect(a.projection[('w', 'task', 't')], {
        'title': 'changed',
        'estimated_seconds': 120,
      });
      final delete = op('c', 1, action: 'delete');
      a.receive(delete);
      b.receive(delete);
      c.receive(delete);
      for (final value in operations) {
        a.receive(value);
      }
      expect(a.projection, isEmpty);
      expect(b.projection, a.projection);
      expect(c.projection, a.projection);
    },
  );
}
