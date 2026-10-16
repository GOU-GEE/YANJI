import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/sync/operation_pipeline.dart';

import '../support/identities.dart';

void main() {
  test('legacy duplicate subjects preserve records, hierarchy, edits and deterministic replay', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final replicaDb = AppDatabase(NativeDatabase.memory());
    final identity = await testIdentity(
      '01991f82-0000-7000-8000-000000000271',
      71,
    );
    var time = DateTime(2026, 10, 2, 9);
    var app = await StudyAppController.open(db, identity, now: () => time);
    final replica = await StudyAppController.open(
      replicaDb,
      identity,
      now: () => time,
    );
    const duplicateMath = '01991f82-0000-7000-8000-000000000281';
    const duplicateChild = '01991f82-0000-7000-8000-000000000282';
    try {
      await app.onboard(
        name: '学习目标',
        date: '2028-12-20',
        subjectNames: ['数学', '政治'],
      );
      final math = app.subjects.singleWhere((s) => s.name == '数学').id;
      final politics = app.subjects.singleWhere((s) => s.name == '政治').id;
      await app.saveSubject(name: '基础', parentId: math);
      await app.saveSubject(name: '基础', parentId: politics);
      final child = app.subjects
          .singleWhere((s) => s.parentSubjectId == math)
          .id;
      await app.startStudy(child);
      time = time.add(const Duration(minutes: 3));
      await app.stopStudy();
      final workspace = app.workspace!.id;
      await app.writer.executeBatch([
        BusinessCommand(
          workspaceId: workspace,
          entityType: 'subject',
          entityId: duplicateMath,
          action: 'create',
          payload: {'name': ' 数学 ', 'sort_order': 0},
        ),
        BusinessCommand(
          workspaceId: workspace,
          entityType: 'subject',
          entityId: duplicateChild,
          action: 'create',
          payload: {
            'name': '基础',
            'parent_subject_id': duplicateMath,
            'sort_order': 1,
          },
        ),
      ]);
      await app.refresh();
      expect(app.subjects, hasLength(4));
      final mergedMath = app.subjects.singleWhere((s) => s.name == '数学').id;
      final mergedChild = app.subjects
          .singleWhere((s) => s.name == '基础' && s.parentSubjectId == mergedMath)
          .id;
      expect(app.subjects.where((s) => s.name == '基础'), hasLength(2));
      expect(app.sessions.single.subjectId, mergedChild);
      await app.saveTask(
        title: '合并后的任务',
        date: app.today,
        subjectId: mergedChild,
      );
      await app.startStudy(mergedChild, taskId: app.tasks.single.id);
      time = time.add(const Duration(minutes: 7));
      await app.stopStudy();
      expect(app.dayDuration(time), 10 * 60 * 1000);
      // Reproduce the old app's materialized duplicate rows; signed history stays unchanged.
      final historyCount = (await app.applier.export(workspace)).length;
      await db.customStatement(
        'INSERT INTO subjects(id,workspace_id,name,sort_order) VALUES(?,?,?,0)',
        [math == mergedMath ? duplicateMath : math, workspace, '数学'],
      );
      app.dispose();
      app = await StudyAppController.open(db, identity, now: () => time);
      expect(app.subjects, hasLength(4));
      expect((await app.applier.export(workspace)).length, historyCount);
      expect(app.dayDuration(time), 10 * 60 * 1000);
      await app.saveSubject(id: mergedChild, name: '高等数学');
      expect(app.subjects.where((s) => s.name == '高等数学'), hasLength(1));
      expect(app.subjects.where((s) => s.name == '基础'), hasLength(1));
      await app.deleteSubject(app.subject(mergedChild)!);
      expect(app.subject(mergedChild)!.archived, 1);
      await app.restoreSubject(app.subject(mergedChild)!);
      expect(app.subject(mergedChild)!.archived, 0);
      expect(app.dayDuration(time), 10 * 60 * 1000);
      final history = await app.applier.export(workspace);
      await replica.applier.receiveBatch(workspace, history.reversed.toList());
      await replica.refresh();
      expect(replica.subjects, hasLength(4));
      expect(replica.dayDuration(time), 10 * 60 * 1000);
      expect(replica.tasks.single.subjectId, mergedChild);
      expect(
        await replica.applier.projectionDigest(workspace),
        await app.applier.projectionDigest(workspace),
      );
      await replica.applier.receiveBatch(workspace, history);
      expect(
        await replica.applier.projectionDigest(workspace),
        await app.applier.projectionDigest(workspace),
      );
    } finally {
      app.dispose();
      replica.dispose();
      await db.close();
      await replicaDb.close();
    }
  });
}
