import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:yanji/application/study_statistics.dart';
import 'package:yanji/core/database/app_database.dart';

StudySession session(String id, String subject) => StudySession(
  id: id,
  workspaceId: 'w',
  subjectId: subject,
  ownerDeviceId: 'd',
  status: 'active',
  startedAtMs: 0,
  mode: 'stopwatch',
);
StudySessionSegment segment(
  String id,
  String sessionId,
  DateTime start,
  DateTime? end,
) => StudySessionSegment(
  id: id,
  workspaceId: 'w',
  sessionId: sessionId,
  startedAtMs: start.millisecondsSinceEpoch,
  endedAtMs: end?.millisecondsSinceEpoch,
);

void main() {
  setUpAll(tzdata.initializeTimeZones);
  test('week split, pauses, live segment, zero days, subject totals and longest streak', () {
    final zone = tz.getLocation('Asia/Shanghai');
    DateTime at(int month, int day, int hour, [int minute = 0]) =>
        tz.TZDateTime(zone, 2026, month, day, hour, minute);
    final snapshot = StudyStatistics(
      sessions: [session('a', 'math'), session('b', 'english')],
      segments: [
        segment('1', 'a', at(8, 24, 10), at(8, 24, 11)),
        segment('2', 'a', at(8, 30, 23, 50), at(8, 31, 0, 10)),
        segment('3', 'b', at(9, 1, 10), at(9, 1, 10, 20)),
        segment('4', 'b', at(9, 1, 10, 40), at(9, 1, 11)),
        segment('5', 'b', at(9, 4, 11), null),
        segment('orphan', 'missing', at(9, 2, 0), at(9, 3, 0)),
        segment('future', 'a', at(9, 5, 0), at(9, 5, 1)),
      ],
      zone: zone,
      now: at(9, 4, 12),
    );
    const minute = 60000;
    expect(snapshot.total, 180 * minute);
    expect(snapshot.weekValues, [
      10 * minute,
      40 * minute,
      0,
      0,
      60 * minute,
      null,
      null,
    ]);
    expect(snapshot.weekTotal, 110 * minute);
    expect(snapshot.previousWeekTotal, 70 * minute);
    expect(snapshot.weekChange, closeTo(57.142857, .00001));
    expect(snapshot.bySubject, {'math': 80 * minute, 'english': 100 * minute});
    expect(snapshot.bySubjectIn(DateTime(2026, 9, 1), DateTime(2026, 9, 4)), {
      'english': 100 * minute,
    });
    expect(snapshot.bySubjectIn(DateTime(2026, 8, 30), DateTime(2026, 8, 31)), {
      'math': 20 * minute,
    });
    expect(snapshot.weekBySubject, {
      'math': 10 * minute,
      'english': 100 * minute,
    });
    expect(snapshot.todayDuration, 60 * minute);
    expect(snapshot.learningDays, 5);
    expect(snapshot.longestStreak, 3);
    expect(snapshot.currentStreak, 1);
    expect(snapshot.calendarDays, 12);
    expect(snapshot.averagePerDay, 36 * minute);
    expect(snapshot.daily.values.reduce((a, b) => a + b), snapshot.total);
  });
  for (final (month, day, hours) in [(3, 8, 23), (11, 1, 25)]) {
    test('civil day remains one day across $hours-hour DST boundary', () {
      final zone = tz.getLocation('America/New_York');
      final start = tz.TZDateTime(zone, 2026, month, day);
      final end = tz.TZDateTime(zone, 2026, month, day + 1);
      final stats = StudyStatistics(
        sessions: [session('a', 'math')],
        segments: [segment('1', 'a', start, end)],
        zone: zone,
        now: end,
      );
      expect(stats.total, hours * 3600000);
      expect(stats.learningDays, 1);
      expect(stats.todayDuration, 0);
      expect(stats.currentStreak, 1); // Today empty, yesterday carries streak.
      expect(stats.longestStreak, 1);
      expect(stats.calendarDays, 2);
      expect(stats.averagePerDay, hours * 3600000);
      expect(stats.previousWeekTotal, stats.total);
      expect(stats.weekChange, -100);
    });
  }
  test('no learning is zero; zero-length segments do not create learning days or comparison', () {
    final now = DateTime.utc(2026, 9, 4);
    final stats = StudyStatistics(
      sessions: [session('a', 'math')],
      segments: [segment('1', 'a', now, now)],
      zone: tz.UTC,
      now: now,
    );
    expect(stats.total, 0);
    expect(stats.learningDays, 0);
    expect(stats.averagePerDay, 0);
    expect(stats.longestStreak, 0);
    expect(stats.currentStreak, 0);
    expect(stats.weekChange, isNull);
    expect(stats.weekValues, [0, 0, 0, 0, 0, null, null]);
  });
  test(
    'completed end is capped at snapshot time; stale subject still contributes',
    () {
      final now = DateTime.utc(2026, 9, 4, 12);
      final stats = StudyStatistics(
        sessions: [session('a', 'removed-subject')],
        segments: [
          segment(
            '1',
            'a',
            now.subtract(const Duration(hours: 1)),
            now.add(const Duration(hours: 1)),
          ),
        ],
        zone: tz.UTC,
        now: now,
      );
      expect(stats.total, 3600000);
      expect(stats.bySubject, {'removed-subject': 3600000});
      expect(stats.weekTotal, 3600000);
      expect(stats.weekChange, isNull);
    },
  );
}
