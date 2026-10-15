import 'dart:math';

import 'package:timezone/timezone.dart' as tz;

import '../core/database/app_database.dart';

/// Ephemeral read model rebuilt from the production projection, never persisted.
/// Calendar keys are UTC *labels*, not timestamps used for measuring durations.
class StudyStatistics {
  StudyStatistics({
    required List<StudySession> sessions,
    required List<StudySessionSegment> segments,
    required tz.Location zone,
    required DateTime now,
  }) {
    _segments = segments;
    _zone = zone;
    _nowMs = now.millisecondsSinceEpoch;
    final local = tz.TZDateTime.from(now, zone);
    today = DateTime.utc(local.year, local.month, local.day);
    monday = today.subtract(Duration(days: today.weekday - 1));
    final weekStart = tz.TZDateTime(
      zone,
      monday.year,
      monday.month,
      monday.day,
    ).millisecondsSinceEpoch;
    final nowMs = now.millisecondsSinceEpoch;
    final owners = {for (final s in sessions) s.id: s.subjectId};
    _owners = owners;
    for (final segment in segments) {
      if (!owners.containsKey(segment.sessionId)) continue;
      final end = min(segment.endedAtMs ?? nowMs, nowMs);
      if (end <= segment.startedAtMs) continue;
      final subject = owners[segment.sessionId]!;
      final duration = end - segment.startedAtMs;
      total += duration;
      bySubject.update(subject, (v) => v + duration, ifAbsent: () => duration);
      final todayStart = tz.TZDateTime(
        zone,
        local.year,
        local.month,
        local.day,
      ).millisecondsSinceEpoch;
      final todayEnd = tz.TZDateTime(
        zone,
        local.year,
        local.month,
        local.day + 1,
      ).millisecondsSinceEpoch;
      final todayDuration = max<int>(
        0,
        min<int>(end, todayEnd) - max<int>(segment.startedAtMs, todayStart),
      );
      if (todayDuration > 0) {
        dayBySubject.update(
          subject,
          (v) => v + todayDuration,
          ifAbsent: () => todayDuration,
        );
      }
      final inWeek = max<int>(
        0,
        end - max<int>(weekStart, segment.startedAtMs),
      );
      if (inWeek > 0) {
        weekBySubject.update(
          subject,
          (v) => v + inWeek,
          ifAbsent: () => inWeek,
        );
      }
      var cursor = segment.startedAtMs;
      while (cursor < end) {
        final day = tz.TZDateTime.fromMillisecondsSinceEpoch(zone, cursor);
        final boundary = tz.TZDateTime(
          zone,
          day.year,
          day.month,
          day.day + 1,
        ).millisecondsSinceEpoch;
        final next = min(end, boundary);
        final key = DateTime.utc(day.year, day.month, day.day);
        daily.update(
          key,
          (v) => v + next - cursor,
          ifAbsent: () => next - cursor,
        );
        cursor = next;
      }
    }
    final dates = daily.keys.toList()..sort();
    var run = 0;
    DateTime? previous;
    for (final date in dates) {
      run = previous != null && date.difference(previous).inDays == 1
          ? run + 1
          : 1;
      longestStreak = max(longestStreak, run);
      previous = date;
    }
    if (dates.isNotEmpty) {
      calendarDays = today.difference(dates.first).inDays + 1;
      var cursor = daily.containsKey(today)
          ? today
          : today.subtract(const Duration(days: 1));
      while (daily.containsKey(cursor)) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }
  }

  late final DateTime today, monday;
  late final List<StudySessionSegment> _segments;
  late final Map<String, String> _owners;
  late final tz.Location _zone;
  late final int _nowMs;
  final Map<DateTime, int> daily = {};
  final Map<String, int> bySubject = {}, weekBySubject = {}, dayBySubject = {};
  int total = 0, longestStreak = 0, currentStreak = 0, calendarDays = 0;
  int get learningDays => daily.length;
  int get averagePerDay => learningDays == 0 ? 0 : total ~/ learningDays;
  int get todayDuration => daily[today] ?? 0;

  /// Clip each real session segment to local calendar-day boundaries. This
  /// keeps month and custom ranges correct across midnight and DST changes.
  Map<String, int> bySubjectIn(DateTime firstDay, DateTime lastDay) {
    final start = tz.TZDateTime(
      _zone,
      firstDay.year,
      firstDay.month,
      firstDay.day,
    ).millisecondsSinceEpoch;
    final end = tz.TZDateTime(
      _zone,
      lastDay.year,
      lastDay.month,
      lastDay.day + 1,
    ).millisecondsSinceEpoch;
    final values = <String, int>{};
    for (final segment in _segments) {
      final subject = _owners[segment.sessionId];
      if (subject == null) continue;
      final clipped = max<int>(
        0,
        min<int>(min<int>(segment.endedAtMs ?? _nowMs, _nowMs), end) -
            max<int>(segment.startedAtMs, start),
      );
      if (clipped > 0) {
        values.update(
          subject,
          (value) => value + clipped,
          ifAbsent: () => clipped,
        );
      }
    }
    return values;
  }

  List<DateTime> get weekDays =>
      List.generate(7, (i) => monday.add(Duration(days: i)));
  List<int?> get weekValues =>
      weekDays.map((d) => d.isAfter(today) ? null : daily[d] ?? 0).toList();
  int get weekTotal => weekBySubject.values.fold(0, (a, b) => a + b);
  int get previousWeekTotal => List.generate(
    7,
    (i) => monday.subtract(Duration(days: 7 - i)),
  ).fold(0, (sum, day) => sum + (daily[day] ?? 0));
  double? get weekChange => previousWeekTotal == 0
      ? null
      : (weekTotal - previousWeekTotal) / previousWeekTotal * 100;
}

String exactStudyDuration(int milliseconds) {
  final seconds = max(0, milliseconds) ~/ 1000;
  return '${seconds ~/ 3600} 小时 ${(seconds ~/ 60) % 60} 分 ${seconds % 60} 秒';
}
