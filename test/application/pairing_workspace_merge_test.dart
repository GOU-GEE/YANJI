import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/sync/pairing/pairing_invite.dart';
import 'package:yanji/sync/oplog/operation.dart';

import '../support/identities.dart';

void main() {
  test('merges two initialized workspaces, preserves history, durations and selection across reopen', () async {
    final directory = await Directory.systemTemp.createTemp('yanji-merge-');
    final aDb = AppDatabase(NativeDatabase.memory());
    var bDb = AppDatabase(NativeDatabase(File('${directory.path}/b.sqlite')));
    final aIdentity = await testIdentity(
      '01991f82-0000-7000-8000-000000000211',
      11,
    );
    final bIdentity = await testIdentity(
      '01991f82-0000-7000-8000-000000000212',
      12,
    );
    final a = await StudyAppController.open(aDb, aIdentity);
    var time = DateTime(2026, 10, 2, 9);
    var b = await StudyAppController.open(bDb, bIdentity, now: () => time);
    try {
      await a.onboard(
        name: '平板目标',
        date: '2027-12-20',
        subjectNames: ['数学', '英语'],
      );
      await b.onboard(
        name: '手机目标',
        date: '2027-12-20',
        subjectNames: ['数学', '政治'],
      );
      final aMath = a.subjects.singleWhere((s) => s.name == '数学').id;
      final bMath = b.subjects.singleWhere((s) => s.name == '数学').id;
      await a.saveSubject(name: '高数', parentId: aMath);
      await b.saveSubject(name: '高数', parentId: bMath);
      await b.saveSubject(name: '线性代数', parentId: bMath);
      final aHigher = a.subjects.singleWhere((s) => s.name == '高数').id;
      final bHigher = b.subjects.singleWhere((s) => s.name == '高数').id;
      final original = b.workspace!.id;
      await a.saveTask(title: '平板任务', date: a.today);
      await b.saveTask(title: '手机任务', date: b.today, subjectId: bHigher);
      await b.startStudy(bHigher, taskId: b.tasks.first.id);
      time = time.add(const Duration(minutes: 7));
      await b.pauseStudy();
      time = time.add(const Duration(minutes: 2));
      await b.resumeStudy();
      time = time.add(const Duration(minutes: 3));
      await b.stopStudy();
      final originalHistory = await b.applier.export(original);
      final genesis = await a.ensureWorkspaceGenesis();
      await a.addTrustedPeer(
        deviceId: bIdentity.deviceId,
        deviceName: '手机',
        platform: 'android',
        identityPublicKey: Uint8List.fromList(bIdentity.publicKey.bytes),
        tlsCertificateSha256: Uint8List(32),
      );
      final invite = PairingInvite.create(
        workspaceId: a.workspace!.id,
        workspaceGenesisHash: genesis,
        inviterDeviceId: aIdentity.deviceId,
        identityPublicKey: Uint8List.fromList(aIdentity.publicKey.bytes),
        tlsCertificateSha256: Uint8List(32),
        port: 12345,
        nowMs: time.millisecondsSinceEpoch,
      );
      final history = await a.applier.export(a.workspace!.id);
      // Explicit choice is required before changing the selected workspace.
      await expectLater(
        b.importPairedHistory(invite, history),
        throwsStateError,
      );
      expect(b.workspace!.id, original);
      await b.importPairedHistory(invite, history, mergeExisting: true);
      expect(b.workspace!.id, a.workspace!.id);
      expect(b.tasks.map((t) => t.title), containsAll(['手机任务', '平板任务']));
      expect(
        b.subjects.map((s) => s.name),
        containsAll(['英语', '数学', '政治', '高数', '线性代数']),
      );
      expect(b.subjects, hasLength(5));
      expect(b.subjects.singleWhere((s) => s.name == '数学').id, aMath);
      expect(b.subjects.singleWhere((s) => s.name == '高数').id, aHigher);
      expect(
        b.subjects.singleWhere((s) => s.name == '线性代数').parentSubjectId,
        aMath,
      );
      expect(b.tasks.singleWhere((t) => t.title == '手机任务').subjectId, aHigher);
      expect(b.sessions.single.subjectId, aHigher);
      expect(
        b.segments
            .where((s) => s.endedAtMs != null)
            .fold<int>(0, (n, s) => n + s.endedAtMs! - s.startedAtMs),
        10 * 60 * 1000,
      );
      expect(
        await b.applier.export(original),
        hasLength(originalHistory.length),
      );
      for (final op in await b.applier.export(b.workspace!.id)) {
        await a.applier.receive(
          op,
          workspaceId: a.workspace!.id,
          originDeviceId: op.parse().originDeviceId,
        );
      }
      await a.refresh();
      expect(a.tasks.map((t) => t.title), containsAll(['手机任务', '平板任务']));
      expect(a.subjects, hasLength(5));
      expect(a.sessions.single.subjectId, aHigher);
      expect(
        await a.applier.projectionDigest(a.workspace!.id),
        await b.applier.projectionDigest(b.workspace!.id),
      );
      b.dispose();
      await bDb.close();
      bDb = AppDatabase(NativeDatabase(File('${directory.path}/b.sqlite')));
      b = await StudyAppController.open(bDb, bIdentity, now: () => time);
      expect(b.workspace!.id, a.workspace!.id);
      expect(b.tasks.map((t) => t.title), containsAll(['手机任务', '平板任务']));
      // A corrupt remote packet must not change the selected local space.
      final bad = Operation(
        envelopeBytes: history.first.envelopeBytes,
        signature: Uint8List(64),
      );
      await expectLater(b.importPairedHistory(invite, [bad]), throwsStateError);
      expect(b.workspace!.id, a.workspace!.id);
    } finally {
      a.dispose();
      b.dispose();
      await aDb.close();
      await bDb.close();
      await directory.delete(recursive: true);
    }
  });
}
