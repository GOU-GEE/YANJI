import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/exam_schedule.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';

import '../support/identities.dart';

void main() {
  test(
    'admission year uses prior year, announced dates and explicit estimates',
    () {
      expect(ExamSchedule.dateFor(2026), DateTime.utc(2025, 12, 20));
      expect(ExamSchedule.isAnnounced(2026), isTrue);
      expect(ExamSchedule.dateFor(2028), DateTime.utc(2027, 12, 25));
      expect(ExamSchedule.isEstimate(2028, DateTime(2027, 12, 25)), isTrue);
      expect(ExamSchedule.nextYear(DateTime(2027, 12, 25)), 2028);
      expect(ExamSchedule.nextYear(DateTime(2027, 12, 26)), 2029);
    },
  );
  test(
    'year selection persists through writer and countdown uses calendar days',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final identity = await testIdentity(
        '01991f82-0000-7000-8000-000000000101',
        1,
      );
      var now = DateTime.utc(2027, 12, 24, 15, 59);
      var app = await StudyAppController.open(db, identity, now: () => now);
      try {
        await app.onboard(
          name: '旧目标',
          date: '2028-12-20',
          subjectNames: ['数学'],
        );
        await app.setExamYear(2028);
        expect(app.exam?.examDate, '2027-12-25');
        expect(app.daysUntilExam, 1);
        expect(app.examDateEstimated, isTrue);
        now = now.add(const Duration(minutes: 1));
        expect(app.daysUntilExam, 0);
        app.dispose();
        app = await StudyAppController.open(db, identity, now: () => now);
        expect(app.examYear, 2028);
        expect(app.exam?.examDate, '2027-12-25');
        expect(app.subjects.single.name, '数学');
        await app.setExamYear(2028, date: DateTime(2027, 12, 26));
        expect(app.examDateEstimated, isFalse);
        expect(app.daysUntilExam, 1);
      } finally {
        app.dispose();
        await db.close();
      }
    },
  );
}
