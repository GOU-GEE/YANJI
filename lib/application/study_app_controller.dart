import 'dart:math';

import 'study_statistics.dart';
import 'exam_schedule.dart';

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/crypto/device_identity.dart';
import '../core/database/app_database.dart';
import '../core/ids/entity_ids.dart';
import '../sync/operation_pipeline.dart';
import '../sync/oplog/operation_journal.dart';

String calendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String durationLabel(int milliseconds) {
  final minutes = max(0, milliseconds) ~/ 60000;
  return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
}

String clockLabel(int milliseconds) {
  final seconds = max(0, milliseconds) ~/ 1000;
  return '${'${seconds ~/ 3600}'.padLeft(2, '0')}:${((seconds ~/ 60) % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Application boundary: presentation sees snapshots and commands, never DAOs.
/// Single-device policy permits only this installation's identity. No remote
/// origins or network receive entry point is exposed by this UI composition.
class StudyAppController extends ChangeNotifier {
  StudyAppController._(this.database, this.identity, this.ids, this.now) {
    applier = OperationApplier(
      database,
      identity,
      lookupOrigin: (workspace, origin) async => origin == identity.deviceId
          ? OriginPolicy(publicKey: identity.publicKey, authorized: true)
          : null,
      ids: ids,
      nowMs: () => now().millisecondsSinceEpoch,
    );
    writer = OperationWriter(applier);
  }
  static Future<StudyAppController> open(
    AppDatabase db,
    DeviceIdentity identity, {
    EntityIds? ids,
    DateTime Function()? now,
  }) async {
    tzdata.initializeTimeZones();
    final controller = StudyAppController._(
      db,
      identity,
      ids ?? EntityIds(),
      now ?? DateTime.now,
    );
    await controller.refresh();
    // Seed a small set of child-subject records for the in-development stats
    // screen. This runs once per workspace, only when child subjects exist and
    // none has a recorded segment yet.
    await controller._seedMockChildSessions();
    if (controller.workspace != null &&
        controller.workspace!.createdByDeviceId != identity.deviceId) {
      controller.dispose();
      throw StateError('当前身份不拥有本机工作区，不能自动重新授权');
    }
    return controller;
  }

  final AppDatabase database;
  final DeviceIdentity identity;
  final EntityIds ids;
  final DateTime Function() now;
  late final OperationApplier applier;
  late final OperationWriter writer;
  Workspace? workspace;
  ExamProfile? exam;
  List<Subject> subjects = [];
  List<Task> tasks = [];
  List<StudySession> sessions = [];
  List<StudySessionSegment> segments = [];
  List<DailyReview> reviews = [];
  bool busy = false;
  String? error;
  bool get isReady => workspace != null && exam != null;
  tz.Location get zone =>
      tz.getLocation(workspace?.statsTimezone ?? 'Asia/Shanghai');
  tz.TZDateTime get localNow => tz.TZDateTime.from(now(), zone);
  String get today => calendarDate(localNow);
  List<Subject> get activeSubjects => subjects
      .where((s) => s.archived == 0 && s.parentSubjectId == null)
      .toList();
  List<Subject> get studySubjects {
    final visible = subjects.where(isSubjectVisible).toList();
    final parentsWithChildren = visible
        .map((s) => s.parentSubjectId)
        .whereType<String>()
        .toSet();
    return visible
        .where(
          (s) =>
              s.parentSubjectId != null || !parentsWithChildren.contains(s.id),
        )
        .toList();
  }

  List<Task> get todayTasks => tasks
      .where(
        (t) =>
            t.status != 'cancelled' &&
            (t.scheduledDate == today ||
                (t.repeatDaily == 1 &&
                    (t.scheduledDate == null ||
                        t.scheduledDate!.compareTo(today) <= 0))),
      )
      .toList();
  StudySession? get runningSession {
    final values = sessions
        .where(
          (s) =>
              s.ownerDeviceId == identity.deviceId && s.status != 'completed',
        )
        .toList();
    return values.isEmpty ? null : values.last;
  }

  Subject? subject(String? id) => subjects.where((s) => s.id == id).firstOrNull;
  Task? task(String? id) => tasks.where((t) => t.id == id).firstOrNull;

  Future<void> _seedMockChildSessions() async {
    if (workspace == null) return;
    final children = subjects
        .where((s) => isSubjectVisible(s) && s.parentSubjectId != null)
        .toList();
    if (children.isEmpty ||
        segments.any(
          (s) => children.any(
            (c) =>
                c.id ==
                sessions
                    .where((x) => x.id == s.sessionId)
                    .firstOrNull
                    ?.subjectId,
          ),
        )) {
      return;
    }
    final base = now().millisecondsSinceEpoch;
    for (var i = 0; i < children.length; i++) {
      final duration = (i + 1) * 20 * 60000;
      final sessionId = ids.next();
      final segmentId = ids.next();
      final start = base - duration - i * 86400000;
      await _write('study_session', sessionId, 'session.start', {
        'owner_device_id': identity.deviceId,
        'subject_id': children[i].id,
        'started_at_ms': start,
        'segment_id': segmentId,
        'mode': 'stopwatch',
      });
      await _write('study_session', sessionId, 'session.stop', {
        'segment_id': segmentId,
        'ended_at_ms': start + duration,
      });
    }
    await refresh();
  }

  DailyReview? review(String date) =>
      reviews.where((r) => r.reviewDate == date).firstOrNull;
  int get examYear =>
      ExamSchedule.yearFromName(exam?.examName) ??
      (DateTime.tryParse(exam?.examDate ?? '')?.year ?? localNow.year) + 1;
  bool get examDateEstimated {
    final date = DateTime.tryParse(exam?.examDate ?? '');
    return date != null && ExamSchedule.isEstimate(examYear, date);
  }

  Future<void> setExamYear(int year, {DateTime? date}) => _perform(() async {
    final automaticDate = ExamSchedule.dateFor(year);
    await _write('exam_profile', exam!.id, 'update', {
      'exam_name': '$year 考研',
      'exam_date': calendarDate(date ?? automaticDate),
    });
  });

  int get daysUntilExam {
    final parsed = DateTime.tryParse(exam?.examDate ?? '');
    if (parsed == null) return 0;
    final current = localNow;
    return max(
      0,
      DateTime.utc(parsed.year, parsed.month, parsed.day)
          .difference(DateTime.utc(current.year, current.month, current.day))
          .inDays,
    );
  }

  Future<void> refresh() async {
    final workspaces = await database.select(database.workspaces).get();
    workspace = workspaces.firstOrNull;
    final profiles = await database.select(database.examProfiles).get();
    exam = profiles.where((e) => e.workspaceId == workspace?.id).firstOrNull;
    subjects =
        (await database.select(database.subjects).get())
            .where((s) => s.workspaceId == workspace?.id)
            .toList()
          ..sort(
            (a, b) => a.sortOrder != b.sortOrder
                ? a.sortOrder.compareTo(b.sortOrder)
                : a.id.compareTo(b.id),
          );
    tasks =
        (await database.select(database.tasks).get())
            .where((t) => t.workspaceId == workspace?.id)
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
    sessions =
        (await database.select(database.studySessions).get())
            .where((s) => s.workspaceId == workspace?.id)
            .toList()
          ..sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));
    segments = (await database.select(database.studySessionSegments).get())
        .where((s) => s.workspaceId == workspace?.id)
        .toList();
    reviews = (await database.select(database.dailyReviews).get())
        .where((s) => s.workspaceId == workspace?.id)
        .toList();
    await _completeReachedTasks();
    notifyListeners();
  }

  bool isTaskCompleted(Task task) =>
      task.status == 'completed' &&
      (task.repeatDaily == 0 ||
          (task.completedAtMs != null &&
              calendarDate(
                    tz.TZDateTime.fromMillisecondsSinceEpoch(
                      zone,
                      task.completedAtMs!,
                    ),
                  ) ==
                  today));

  int taskDuration(String taskId) {
    final current = localNow;
    final from = task(taskId)?.repeatDaily == 1
        ? tz.TZDateTime(
            zone,
            current.year,
            current.month,
            current.day,
          ).millisecondsSinceEpoch
        : 0;
    final until = now().millisecondsSinceEpoch;
    final linked = sessions
        .where((s) => s.taskId == taskId)
        .map((s) => s.id)
        .toSet();
    return segments
        .where((s) => linked.contains(s.sessionId))
        .fold(
          0,
          (total, s) =>
              total +
              max(
                0,
                min(s.endedAtMs ?? until, until) - max(s.startedAtMs, from),
              ),
        );
  }

  List<Task> get _reachedTasks => tasks
      .where(
        (t) =>
            !isTaskCompleted(t) &&
            t.status != 'cancelled' &&
            (t.estimatedSeconds ?? 0) > 0 &&
            taskDuration(t.id) >= t.estimatedSeconds! * 1000,
      )
      .toList();

  Future<void> _completeReachedTasks() async {
    if (workspace?.createdByDeviceId != identity.deviceId) return;
    final reached = _reachedTasks;
    for (final task in reached) {
      await _write('task', task.id, 'update', {
        'status': 'completed',
        'completed_at_ms': now().millisecondsSinceEpoch,
      });
    }
    if (reached.isNotEmpty) {
      tasks =
          (await database.select(database.tasks).get())
              .where((t) => t.workspaceId == workspace?.id)
              .toList()
            ..sort((a, b) => b.priority.compareTo(a.priority));
    }
  }

  String? _progressDay;
  Future<void> tickTaskProgress() async {
    if (busy) return;
    if (_reachedTasks.isNotEmpty) {
      await _perform(() async {});
    } else if (runningSession != null || _progressDay != today) {
      notifyListeners();
    }
    _progressDay = today;
  }

  Future<void> _perform(Future<void> Function() operation) async {
    if (busy) throw StateError('上一项操作尚未完成');
    busy = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      await refresh();
    } catch (e) {
      error = '保存未完成，请重试。';
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _write(
    String type,
    String id,
    String action,
    Map<String, Object?> payload, {
    String? workspaceId,
  }) async {
    await writer.execute(
      BusinessCommand(
        workspaceId: workspaceId ?? workspace!.id,
        entityType: type,
        entityId: id,
        action: action,
        payload: payload,
      ),
    );
  }

  Future<void> onboard({
    required String name,
    required String date,
    String? school,
    String? major,
    int? totalScore,
    required List<String> subjectNames,
  }) => _perform(() async {
    if (isReady) throw StateError('已经完成设置');
    if (name.trim().isEmpty ||
        DateTime.tryParse(date) == null ||
        subjectNames.isEmpty) {
      throw ArgumentError('请填写考试和科目');
    }
    final id = ids.next();
    await database.transaction(() async {
      await _write('workspace', id, 'create', {
        'name': name.trim(),
        'stats_timezone': 'Asia/Shanghai',
        'created_at_ms': now().millisecondsSinceEpoch,
        'created_by_device_id': identity.deviceId,
      }, workspaceId: id);
      await _write('exam_profile', 'exam_profile/$id/default', 'create', {
        'exam_name': name.trim(),
        'exam_date': date,
        'target_school': school,
        'target_major': major,
        'target_total_score_x100': totalScore,
      }, workspaceId: id);
      for (var i = 0; i < subjectNames.length; i++) {
        await _write('subject', ids.next(), 'create', {
          'name': subjectNames[i].trim(),
          'sort_order': i,
        }, workspaceId: id);
      }
    });
  });
  Future<void> saveSubject({
    String? id,
    required String name,
    int? score,
    String? parentId,
  }) => _perform(() async {
    if (name.trim().isEmpty) throw ArgumentError('请填写科目名称');
    final parent = parentId ?? subject(id)?.parentSubjectId;
    if (parent != null &&
        (subject(parent) == null ||
            subject(parent)!.parentSubjectId != null ||
            parent == id)) {
      throw ArgumentError('二级科目必须属于一级科目');
    }
    await _write(
      'subject',
      id ?? ids.next(),
      id == null ? 'create' : 'update',
      {
        'name': name.trim(),
        'target_score_x100': score,
        'parent_subject_id': ?parent,
        if (id == null) 'sort_order': subjects.length,
      },
    );
  });
  bool isSubjectVisible(Subject s) =>
      s.archived == 0 &&
      (s.parentSubjectId == null || subject(s.parentSubjectId)?.archived == 0);

  Future<void> archiveSubject(Subject s) =>
      s.archived == 0 ? deleteSubject(s) : restoreSubject(s);
  Future<void> deleteSubject(Subject s) => _perform(() async {
    final ids = {
      s.id,
      ...subjects
          .where((child) => child.parentSubjectId == s.id)
          .map((child) => child.id),
    };
    final running = runningSession;
    await database.transaction(() async {
      if (running != null && ids.contains(running.subjectId)) {
        final segment = _lastSegment(running);
        await _write('study_session', running.id, 'session.stop', {
          'segment_id': segment.id,
          'ended_at_ms':
              segment.endedAtMs ??
              max(segment.startedAtMs, now().millisecondsSinceEpoch),
        });
      }
      await _write('subject', s.id, 'update', {'archived': true});
    });
  });
  Future<void> restoreSubject(Subject s) => _perform(() async {
    await database.transaction(() async {
      if (s.parentSubjectId != null &&
          subject(s.parentSubjectId)?.archived == 1) {
        await _write('subject', s.parentSubjectId!, 'update', {
          'archived': false,
        });
      }
      await _write('subject', s.id, 'update', {'archived': false});
    });
  });
  Future<void> permanentlyDeleteSubject(Subject s) => _perform(() async {
    if (s.archived != 1) throw StateError('请先移入已删除的科目');
    final descendants = subjects
        .where((child) => child.parentSubjectId == s.id)
        .toList();
    await database.transaction(() async {
      for (final child in descendants) {
        await _write('subject', child.id, 'delete', {});
      }
      await _write('subject', s.id, 'delete', {});
    });
  });
  Future<void> moveSubject(Subject s, int direction) => _perform(() async {
    final list = subjects
        .where((item) => item.parentSubjectId == s.parentSubjectId)
        .toList();
    final index = list.indexWhere((item) => item.id == s.id),
        other = index + direction;
    if (index < 0 || other < 0 || other >= list.length) return;
    final swap = list[index];
    list[index] = list[other];
    list[other] = swap;
    await database.transaction(() async {
      for (var i = 0; i < list.length; i++) {
        await _write('subject', list[i].id, 'update', {'sort_order': i});
      }
    });
  });
  Future<void> saveTask({
    String? id,
    required String title,
    String? subjectId,
    String? date,
    int? estimatedSeconds,
    bool repeatDaily = false,
    int priority = 0,
    String? note,
  }) => _perform(() async {
    var resolvedTitle = title.trim();
    if (resolvedTitle.isEmpty &&
        subject(subjectId) != null &&
        (estimatedSeconds ?? 0) > 0) {
      resolvedTitle =
          '学习${subject(subjectId)!.name}${estimatedSeconds! ~/ 60}分钟';
    }
    if (resolvedTitle.isEmpty) throw ArgumentError('请填写名称，或选择科目和时长');
    await _write('task', id ?? ids.next(), id == null ? 'create' : 'update', {
      'title': resolvedTitle,
      'subject_id': subjectId,
      'scheduled_date': date,
      'repeat_daily': repeatDaily,
      'estimated_seconds': estimatedSeconds,
      'priority': priority,
      'note': note,
    });
  });
  Future<void> setTaskStatus(Task task, String status) => _perform(
    () => _write('task', task.id, 'update', {
      'status': status,
      'completed_at_ms': status == 'completed'
          ? now().millisecondsSinceEpoch
          : null,
    }),
  );
  Future<void> startStudy(String subjectId, {String? taskId}) =>
      _perform(() async {
        if (runningSession != null) throw StateError('请先结束当前学习');
        if (!studySubjects.any((s) => s.id == subjectId)) {
          throw ArgumentError('请选择有效科目');
        }
        final linked = task(taskId);
        if (taskId != null &&
            (linked == null ||
                isTaskCompleted(linked) ||
                linked.status == 'cancelled' ||
                (linked.subjectId != null && linked.subjectId != subjectId))) {
          throw ArgumentError('关联任务与学习科目不匹配');
        }
        await _write('study_session', ids.next(), 'session.start', {
          'owner_device_id': identity.deviceId,
          'subject_id': subjectId,
          'task_id': taskId,
          'started_at_ms': now().millisecondsSinceEpoch,
          'segment_id': ids.next(),
          'mode': 'stopwatch',
        });
      });
  StudySessionSegment _lastSegment(StudySession session) {
    final list = segments.where((s) => s.sessionId == session.id).toList()
      ..sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));
    return list.last;
  }

  Future<void> pauseStudy() => _perform(() async {
    final s = runningSession!;
    final segment = _lastSegment(s);
    await _write('study_session', s.id, 'session.pause', {
      'segment_id': segment.id,
      'ended_at_ms': max(segment.startedAtMs, now().millisecondsSinceEpoch),
    });
  });
  Future<void> resumeStudy() => _perform(() async {
    final s = runningSession!;
    await _write('study_session', s.id, 'session.resume', {
      'segment_id': ids.next(),
      'started_at_ms': max(
        _lastSegment(s).endedAtMs!,
        now().millisecondsSinceEpoch,
      ),
    });
  });
  Future<void> stopStudy() => _perform(() async {
    final s = runningSession!;
    final segment = _lastSegment(s);
    await _write('study_session', s.id, 'session.stop', {
      'segment_id': segment.id,
      'ended_at_ms': s.status == 'paused'
          ? segment.endedAtMs
          : max(segment.startedAtMs, now().millisecondsSinceEpoch),
    });
  });
  Future<void> saveReview(String date, String content) => _perform(
    () => _write(
      'daily_review',
      'daily_review/${workspace!.id}/$date',
      review(date) == null ? 'create' : 'update',
      {'review_date': date, 'content': content},
    ),
  );
  int sessionDuration(String id, {int? at}) => segments
      .where((s) => s.sessionId == id)
      .fold(
        0,
        (sum, s) =>
            sum +
            max(
              0,
              (s.endedAtMs ?? at ?? now().millisecondsSinceEpoch) -
                  s.startedAtMs,
            ),
      );
  int durationBetween(int from, int to, {String? subjectId}) {
    final sessionIds = sessions
        .where(
          (s) =>
              subjects.any((v) => v.id == s.subjectId && isSubjectVisible(v)) &&
              (subjectId == null || s.subjectId == subjectId),
        )
        .map((s) => s.id)
        .toSet();
    return segments
        .where((s) => sessionIds.contains(s.sessionId))
        .fold(
          0,
          (sum, s) =>
              sum +
              max(
                0,
                min(to, s.endedAtMs ?? now().millisecondsSinceEpoch) -
                    max(from, s.startedAtMs),
              ),
        );
  }

  int dayDuration(DateTime date, {String? subjectId}) {
    final start = tz.TZDateTime(zone, date.year, date.month, date.day),
        end = tz.TZDateTime(zone, date.year, date.month, date.day + 1);
    return durationBetween(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
      subjectId: subjectId,
    );
  }

  StudyStatistics get statistics => StudyStatistics(
    sessions: sessions
        .where(
          (s) =>
              subjects.any((v) => v.id == s.subjectId && isSubjectVisible(v)),
        )
        .toList(),
    segments: segments,
    zone: zone,
    now: now(),
  );

  int get todayDuration => dayDuration(localNow);
  int get totalDuration => durationBetween(0, now().millisecondsSinceEpoch);
  List<DateTime> get weekDays {
    final n = localNow;
    return List.generate(
      7,
      (i) => tz.TZDateTime(zone, n.year, n.month, n.day - n.weekday + 1 + i),
    );
  }

  int get streak {
    var date = localNow;
    var days = 0;
    if (dayDuration(date) == 0) {
      date = tz.TZDateTime(zone, date.year, date.month, date.day - 1);
    }
    while (dayDuration(date) > 0) {
      days++;
      date = tz.TZDateTime(zone, date.year, date.month, date.day - 1);
    }
    return days;
  }
}
