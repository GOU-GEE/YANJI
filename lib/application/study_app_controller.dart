import 'dart:async';
import 'dart:math';

import 'study_statistics.dart';
import 'exam_schedule.dart';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/crypto/device_identity.dart';
import '../core/database/app_database.dart';
import '../core/ids/entity_ids.dart';
import '../platform/study_live_activity.dart';
import '../sync/operation_pipeline.dart';
import '../sync/oplog/operation.dart';
import '../sync/oplog/operation_journal.dart';
import '../sync/pairing/pairing_invite.dart';
import '../sync/protocol/deterministic_cbor.dart';
import '../sync/trust/trust_chain.dart';

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
/// Remote operations enter only through the verified pairing/sync boundary.
class StudyAppController extends ChangeNotifier {
  static const maxStudyDuration = Duration(hours: 8);
  static const studyCheckpointInterval = Duration(seconds: 30);
  StudyAppController._(this.database, this.identity, this.ids, this.now) {
    trust = TrustChain(database, identity);
    applier = OperationApplier(
      database,
      identity,
      lookupOrigin: trust.lookup,
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
    final selected = await db
        .customSelect(
          'SELECT workspace_id FROM local_workspace_selection WHERE singleton=1',
        )
        .getSingleOrNull();
    controller._selectedWorkspace = selected?.read<String>('workspace_id');
    final existingWorkspaces = await db.select(db.workspaces).get();
    final existingWorkspace =
        existingWorkspaces
            .where((w) => w.id == controller._selectedWorkspace)
            .firstOrNull ??
        existingWorkspaces.firstOrNull;
    if (existingWorkspace != null) {
      await controller.trust.reload(existingWorkspace.id);
      final duplicates = await db
          .customSelect(
            "SELECT name FROM subjects WHERE workspace_id=? GROUP BY trim(name),coalesce(parent_subject_id,'') HAVING COUNT(*)>1 LIMIT 1",
            variables: [Variable(existingWorkspace.id)],
          )
          .getSingleOrNull();
      if (duplicates != null) {
        await controller.applier.rebuildWorkspace(existingWorkspace.id);
      }
    }
    await controller.refresh(completeTasks: false);
    await controller._recoverInterruptedStudy();
    await controller.refresh();
    // Seed a small set of child-subject records for the in-development stats
    // screen. This runs once per workspace, only when child subjects exist and
    // none has a recorded segment yet.
    await controller._seedMockChildSessions();
    final localPeer = controller.trustedPeers
        .where((peer) => peer.deviceId == identity.deviceId && peer.active)
        .firstOrNull;
    if (controller.workspace != null &&
        (localPeer == null ||
            DeterministicCbor.compareBytes(
                  localPeer.publicKey.bytes,
                  identity.publicKey.bytes,
                ) !=
                0)) {
      controller.dispose();
      throw StateError('当前身份未获学习空间授权，不能自动重新授权');
    }
    return controller;
  }

  final AppDatabase database;
  final DeviceIdentity identity;
  final EntityIds ids;
  final DateTime Function() now;
  late final OperationApplier applier;
  late final OperationWriter writer;
  late final TrustChain trust;
  Workspace? workspace;
  String? _selectedWorkspace;
  ExamProfile? exam;
  List<Subject> subjects = [];
  List<Task> tasks = [];
  List<StudySession> sessions = [];
  List<StudySessionSegment> segments = [];
  List<DailyReview> reviews = [];
  bool busy = false;
  String? error;
  bool studyDoNotDisturbEnabled = false;
  int? lastCompletedStudyDuration;
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

  Future<void> saveExamGoal({
    String? school,
    String? major,
    int? totalScoreX100,
  }) => _perform(() async {
    final current = exam;
    if (current == null) throw StateError('尚未创建考试目标');
    if (totalScoreX100 != null && totalScoreX100 < 0) {
      throw ArgumentError('目标分数不能为负数');
    }
    String? optionalText(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    await _write('exam_profile', current.id, 'update', {
      'target_school': optionalText(school),
      'target_major': optionalText(major),
      'target_total_score_x100': totalScoreX100,
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

  Future<void> refresh({bool completeTasks = true}) async {
    final workspaces = await database.select(database.workspaces).get();
    workspace =
        workspaces.where((w) => w.id == _selectedWorkspace).firstOrNull ??
        workspaces.firstOrNull;
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
    if (completeTasks) await _completeReachedTasks();
    notifyListeners();
  }

  final Map<String, ({String status, int? completedAtMs})>
  _pendingTaskStatuses = {};

  bool isTaskCompleted(Task task) =>
      (_pendingTaskStatuses[task.id]?.status ?? task.status) == 'completed' &&
      (task.repeatDaily == 0 ||
          ((_pendingTaskStatuses[task.id]?.completedAtMs ??
                      task.completedAtMs) !=
                  null &&
              calendarDate(
                    tz.TZDateTime.fromMillisecondsSinceEpoch(
                      zone,
                      (_pendingTaskStatuses[task.id]?.completedAtMs ??
                          task.completedAtMs)!,
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
                min(_segmentEnd(s, until), until) - max(s.startedAtMs, from),
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
    final current = runningSession;
    if (current != null &&
        sessionDuration(current.id) >= maxStudyDuration.inMilliseconds) {
      await stopStudy();
      return;
    }
    await checkpointStudyProgress(force: false);
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
      await checkpointStudyProgress();
      unawaited(syncLiveActivity());
    } catch (e) {
      error = '保存未完成，请重试。';
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> syncLiveActivity() async {
    final current = runningSession;
    final snapshotAt = now().millisecondsSinceEpoch;
    final int statusUpdatedAt;
    if (current == null) {
      statusUpdatedAt = snapshotAt;
    } else {
      final segment = _lastSegment(current);
      statusUpdatedAt = current.status == 'paused'
          ? segment.endedAtMs ?? segment.startedAtMs
          : segment.startedAtMs;
    }
    await StudyLiveActivity.sync(
      sessionId: current?.id,
      subject: subject(current?.subjectId)?.name ?? '自由学习',
      status: current?.status ?? 'finished',
      elapsedMilliseconds: current == null ? 0 : sessionDuration(current.id),
      todayTotalMilliseconds: todayDuration,
      doNotDisturbEnabled: studyDoNotDisturbEnabled,
      snapshotAtMilliseconds: snapshotAt,
      statusUpdatedAtMilliseconds: statusUpdatedAt,
    );
  }

  Future<String?> handlePendingLiveActivityAction() async {
    final action = await StudyLiveActivity.consumePendingAction();
    final liveState = await StudyLiveActivity.currentActivityState();
    var current = runningSession;
    if (current == null || busy) return action;

    if (liveState != null) {
      final liveStatus = liveState['status'] as String?;
      final capturedAtMs = liveState['capturedAtMs'] as int?;
      final elapsedSeconds = liveState['elapsedSeconds'] as int?;
      if (capturedAtMs != null && elapsedSeconds != null) {
        if (liveStatus == 'paused' && current.status != 'paused') {
          final databaseDuration = sessionDuration(
            current.id,
            at: capturedAtMs,
          );
          final durationDifference = databaseDuration - elapsedSeconds * 1000;
          final pauseAt =
              capturedAtMs - (durationDifference > 0 ? durationDifference : 0);
          await pauseStudy(atMilliseconds: pauseAt);
        } else if (liveStatus == 'active' && current.status == 'paused') {
          await resumeStudy(atMilliseconds: capturedAtMs);
        } else if (liveStatus == 'active' && current.status == 'active') {
          final databaseDuration = sessionDuration(
            current.id,
            at: capturedAtMs,
          );
          final uncountedPause = databaseDuration - elapsedSeconds * 1000;
          if (uncountedPause > 1500) {
            await pauseStudy(atMilliseconds: capturedAtMs - uncountedPause);
            await resumeStudy(atMilliseconds: capturedAtMs);
          }
        }
        current = runningSession;
        if (current == null) return action;
      }
    }

    if (action == null) return null;
    if (action == 'pause' && current.status != 'paused') {
      await pauseStudy();
    } else if (action == 'resume' && current.status == 'paused') {
      await resumeStudy();
    } else if (action == 'finish') {
      await stopStudy();
    } else if (action == 'dnd') {
      studyDoNotDisturbEnabled = !studyDoNotDisturbEnabled;
      notifyListeners();
      await syncLiveActivity();
    }
    return action;
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

  List<TrustedPeer> get trustedPeers =>
      workspace == null ? const [] : trust.peers(workspace!.id);

  Future<Uint8List> ensureWorkspaceGenesis() async {
    final current = workspace;
    if (current == null) throw StateError('工作区尚未初始化');
    final rows = await database
        .customSelect(
          "SELECT envelope_bytes FROM oplog WHERE workspace_id=? AND entity_type='device' ORDER BY origin_seq",
          variables: [Variable(current.id)],
        )
        .get();
    for (final row in rows) {
      final packet = OperationEnvelope.fromBytes(
        row.read<Uint8List>('envelope_bytes'),
      );
      final payload = packet.payload;
      if (payload is Map<String, Object?> &&
          payload['type'] == 'workspace.genesis' &&
          payload['root_device_id'] == current.createdByDeviceId &&
          packet.originDeviceId == current.createdByDeviceId) {
        return Uint8List.fromList((await Sha256().hash(packet.bytes)).bytes);
      }
    }
    if (current.createdByDeviceId != identity.deviceId) {
      throw StateError('本机授权历史缺少 Workspace Genesis');
    }
    final genesis = await applier.appendSystem(
      workspaceId: current.id,
      entityId: current.id,
      payload: {
        'type': 'workspace.genesis',
        'root_device_id': identity.deviceId,
        'root_device_public_key': Uint8List.fromList(identity.publicKey.bytes),
        'created_at_ms': current.createdAtMs,
      },
    );
    await trust.reload(current.id);
    return Uint8List.fromList(
      (await Sha256().hash(genesis.envelopeBytes)).bytes,
    );
  }

  Future<void> addTrustedPeer({
    required String deviceId,
    required String deviceName,
    required String platform,
    required Uint8List identityPublicKey,
    required Uint8List tlsCertificateSha256,
  }) async {
    final current = workspace ?? (throw StateError('工作区尚未初始化'));
    await applier.appendSystem(
      workspaceId: current.id,
      entityId: deviceId,
      payload: {
        'type': 'device.add',
        'device_id': deviceId,
        'device_name': deviceName.trim(),
        'platform': platform,
        'identity_public_key': identityPublicKey,
        'tls_cert_sha256': tlsCertificateSha256,
        'paired_at_ms': now().millisecondsSinceEpoch,
      },
    );
    await trust.reload(current.id);
    await applier.refreshAuthorization(current.id);
    notifyListeners();
  }

  void notifyPairingChanged() {
    applier.revision++;
    notifyListeners();
  }

  Future<void> renameTrustedPeer(TrustedPeer peer, String name) => _perform(
    () async {
      final value = name.trim();
      if (value.isEmpty || value.length > 40) throw StateError('设备名称请输入一到四十个字');
      if (!peer.active) throw StateError('已撤销的设备不能重命名');
      await applier.appendSystem(
        workspaceId: workspace!.id,
        entityId: peer.deviceId,
        payload: {
          'type': 'device.add',
          'device_id': peer.deviceId,
          'device_name': value,
          'platform': peer.platform,
          'identity_public_key': Uint8List.fromList(peer.publicKey.bytes),
          'tls_cert_sha256': peer.tlsCertificateSha256,
          'paired_at_ms': peer.pairedAtMs,
        },
      );
      await trust.reload(workspace!.id);
    },
  );

  Future<void> revokeTrustedPeer(TrustedPeer peer) async {
    final current = workspace ?? (throw StateError('工作区尚未初始化'));
    if (peer.deviceId == identity.deviceId) {
      throw StateError('不能在本机撤销本机身份');
    }
    final row = await database
        .customSelect(
          'SELECT COALESCE(MAX(origin_seq),0) AS seq FROM oplog WHERE workspace_id=? AND origin_device_id=?',
          variables: [Variable(current.id), Variable(peer.deviceId)],
        )
        .getSingle();
    await applier.appendSystem(
      workspaceId: current.id,
      entityId: peer.deviceId,
      payload: {
        'type': 'device.revoke',
        'target_device_id': peer.deviceId,
        'max_allowed_origin_seq': row.read<int>('seq'),
      },
    );
    await trust.reload(current.id);
    await applier.refreshAuthorization(current.id);
    notifyListeners();
  }

  Future<void> importPairedHistory(
    PairingInvite invite,
    List<Operation> operations, {
    bool mergeExisting = false,
  }) async {
    final original = workspace?.id;
    final different = original != null && original != invite.workspaceId;
    if (different && !mergeExisting) throw StateError('两台设备属于不同学习空间，请先确认合并记录');
    if (different && runningSession != null) {
      throw StateError('请先结束本机正在进行的计时，再合并配对');
    }
    if (busy) throw StateError('上一项操作尚未完成，请稍后重试');
    busy = true;
    notifyListeners();
    try {
      await database.transaction(() async {
        await _importTrustedHistory(invite, operations);
        if (different) {
          await _mergeWorkspaceRecords(original, invite.workspaceId);
        }
        await database.customStatement(
          'INSERT OR REPLACE INTO local_workspace_selection(singleton,workspace_id) VALUES(1,?)',
          [invite.workspaceId],
        );
      });
      _selectedWorkspace = invite.workspaceId;
      await refresh();
    } catch (_) {
      if (original != null) await trust.reload(original);
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _mergeWorkspaceRecords(String original, String target) async {
    Future<List<Map<String, dynamic>>> rows(String table, String id) async =>
        (await database
                .customSelect(
                  'SELECT * FROM $table WHERE workspace_id=?',
                  variables: [Variable(id)],
                )
                .get())
            .map((r) => Map<String, dynamic>.from(r.data))
            .toList();
    final subjects = await rows('subjects', original);
    final tasks = await rows('tasks', original);
    final sessions = await rows('study_sessions', original);
    final segments = await rows('study_session_segments', original);
    final reviews = await rows('daily_reviews', original);
    final idMap = <String, String>{
      for (final row in [...subjects, ...tasks, ...sessions, ...segments])
        row['id'] as String: ids.next(),
    };
    final commands = <BusinessCommand>[];
    void add(
      String type,
      String id,
      String action,
      Map<String, Object?> payload,
    ) => commands.add(
      BusinessCommand(
        workspaceId: target,
        entityType: type,
        entityId: id,
        action: action,
        payload: payload,
      ),
    );
    Map<String, Object?> payload(Map<String, dynamic> row) {
      final result = Map<String, Object?>.from(row)
        ..remove('id')
        ..remove('workspace_id');
      for (final key in ['parent_subject_id', 'subject_id', 'task_id']) {
        if (result[key] != null) {
          result[key] = idMap[result[key]] ?? result[key];
        }
      }
      for (final key in ['archived', 'repeat_daily']) {
        if (result.containsKey(key)) result[key] = result[key] == 1;
      }
      return result;
    }

    final targetSubjects = await rows('subjects', target);
    final byName = <(String?, String), Map<String, dynamic>>{
      for (final row in targetSubjects)
        (row['parent_subject_id'] as String?, (row['name'] as String).trim()):
            row,
    };
    for (final child in [false, true]) {
      for (final row in subjects) {
        final parent = row['parent_subject_id'] as String?;
        if ((parent != null) != child) continue;
        final key = (
          parent == null ? null : idMap[parent],
          (row['name'] as String).trim(),
        );
        final existing = byName[key];
        if (existing != null) {
          idMap[row['id'] as String] = existing['id'] as String;
          final updates = <String, Object?>{};
          if (existing['archived'] == 1 && row['archived'] == 0) {
            updates['archived'] = false;
            existing['archived'] = 0;
          }
          for (final field in [
            'category',
            'target_score_x100',
            'max_score_x100',
          ]) {
            if (existing[field] == null && row[field] != null) {
              updates[field] = row[field];
              existing[field] = row[field];
            }
          }
          if (updates.isNotEmpty) {
            add('subject', existing['id'] as String, 'update', updates);
          }
        } else {
          final values = payload(row)..['name'] = key.$2;
          add('subject', idMap[row['id']]!, 'create', values);
          byName[key] = {
            ...row,
            'id': idMap[row['id']],
            'parent_subject_id': key.$1,
          };
        }
      }
    }
    for (final row in tasks) {
      add('task', idMap[row['id']]!, 'create', payload(row));
    }
    for (final session in sessions) {
      final parts =
          segments.where((r) => r['session_id'] == session['id']).toList()
            ..sort(
              (a, b) => (a['started_at_ms'] as int).compareTo(
                b['started_at_ms'] as int,
              ),
            );
      if (parts.isEmpty) throw StateError('本机计时记录不完整，合并已取消，原记录保留');
      final sessionId = idMap[session['id']]!;
      for (var index = 0; index < parts.length; index++) {
        final part = parts[index];
        final segmentId = idMap[part['id']]!;
        add(
          'study_session',
          sessionId,
          index == 0 ? 'session.start' : 'session.resume',
          {
            if (index == 0) ...{
              'owner_device_id': identity.deviceId,
              'subject_id': idMap[session['subject_id']],
              'task_id': idMap[session['task_id']],
              'knowledge_node_id': session['knowledge_node_id'],
              'mode': session['mode'],
              'note': session['note'],
            },
            'segment_id': segmentId,
            'started_at_ms': part['started_at_ms'],
          },
        );
        add(
          'study_session',
          sessionId,
          index == parts.length - 1 && session['status'] == 'completed'
              ? 'session.stop'
              : 'session.pause',
          {
            'segment_id': segmentId,
            'ended_at_ms': part['ended_at_ms'] ?? part['started_at_ms'],
          },
        );
      }
    }
    final existingReviews = await rows('daily_reviews', target);
    for (final row in reviews) {
      final existing = existingReviews
          .where((r) => r['review_date'] == row['review_date'])
          .firstOrNull;
      if (existing != null && existing['content'] == row['content']) continue;
      add(
        'daily_review',
        'daily_review/$target/${row['review_date']}',
        existing == null ? 'create' : 'update',
        {
          if (existing == null) 'review_date': row['review_date'],
          'content': existing == null
              ? row['content']
              : '${existing['content']}\n\n${row['content']}',
        },
      );
    }
    await writer.executeBatch(commands);
  }

  Future<void> _importTrustedHistory(
    PairingInvite invite,
    List<Operation> operations,
  ) async {
    Operation? genesis;
    for (final operation in operations) {
      final envelope = operation.parse();
      final payload = envelope.payload;
      if (envelope.workspaceId == invite.workspaceId &&
          envelope.entityType == 'device' &&
          payload is Map<String, Object?> &&
          payload['type'] == 'workspace.genesis') {
        genesis = operation;
        break;
      }
    }
    if (genesis == null) throw StateError('邀请设备没有提供学习空间身份记录');
    final envelope = genesis.parse();
    final payload = envelope.payload! as Map<String, Object?>;
    final digest = Uint8List.fromList(
      (await Sha256().hash(envelope.bytes)).bytes,
    );
    if (DeterministicCbor.compareBytes(digest, invite.workspaceGenesisHash) !=
        0) {
      throw StateError('学习空间身份记录与二维码不一致');
    }
    final rootKey = SimplePublicKey(
      payload['root_device_public_key']! as Uint8List,
      type: KeyPairType.ed25519,
    );
    trust.anchorRoot(invite.workspaceId, envelope.originDeviceId, rootKey);
    final pending = operations.toList();
    while (pending.isNotEmpty) {
      final available = <Operation>[];
      for (final operation in pending) {
        final item = operation.parse();
        if (item.workspaceId != invite.workspaceId) {
          throw StateError('配对记录不属于该学习空间');
        }
        if (await trust.lookup(invite.workspaceId, item.originDeviceId) !=
            null) {
          available.add(operation);
        }
      }
      if (available.isEmpty) break;
      final results = await applier.receiveBatch(
        invite.workspaceId,
        available,
        receivedFrom: invite.inviterDeviceId,
      );
      if (results.any((r) => r == ReceiveResult.rejected)) {
        throw StateError('配对记录未通过验证');
      }
      pending.removeWhere(available.contains);
      await trust.reload(invite.workspaceId);
      await applier.refreshAuthorization(invite.workspaceId);
    }
    if (pending.isNotEmpty) {
      throw StateError('授权链不完整，${pending.length} 条操作无法验证');
    }
    await trust.reload(invite.workspaceId);
    final inviter = await trust.lookup(
      invite.workspaceId,
      invite.inviterDeviceId,
    );
    if (inviter == null ||
        !inviter.authorized ||
        inviter.cutoff != null ||
        DeterministicCbor.compareBytes(
              inviter.publicKey.bytes,
              invite.identityPublicKey,
            ) !=
            0) {
      throw StateError('邀请设备未获该学习空间授权');
    }
    final local = await trust.lookup(invite.workspaceId, identity.deviceId);
    if (local == null ||
        !local.authorized ||
        local.cutoff != null ||
        DeterministicCbor.compareBytes(
              local.publicKey.bytes,
              identity.publicKey.bytes,
            ) !=
            0) {
      throw StateError('本机尚未获得配对授权');
    }
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
  Future<void> setTaskStatus(Task task, String status) async {
    if (busy) throw StateError('上一项操作尚未完成');
    final completedAtMs = status == 'completed'
        ? now().millisecondsSinceEpoch
        : null;
    // Publish the intended state before signing/writing and reloading SQLite.
    // Persisted snapshots stay authoritative; a failed save removes this overlay.
    _pendingTaskStatuses[task.id] = (
      status: status,
      completedAtMs: completedAtMs,
    );
    try {
      await _perform(
        () => _write('task', task.id, 'update', {
          'status': status,
          'completed_at_ms': completedAtMs,
        }),
      );
    } finally {
      _pendingTaskStatuses.remove(task.id);
      notifyListeners();
    }
  }

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

  Future<void> pauseStudy({int? atMilliseconds}) => _perform(() async {
    final s = runningSession!;
    final segment = _lastSegment(s);
    await _write('study_session', s.id, 'session.pause', {
      'segment_id': segment.id,
      'ended_at_ms': max(
        segment.startedAtMs,
        min(atMilliseconds ?? now().millisecondsSinceEpoch, _studyDeadline(s)),
      ),
    });
  });
  Future<void> resumeStudy({int? atMilliseconds}) async {
    if (sessionDuration(runningSession!.id) >=
        maxStudyDuration.inMilliseconds) {
      await stopStudy();
      return;
    }
    await _perform(() async {
      final s = runningSession!;
      await _write('study_session', s.id, 'session.resume', {
        'segment_id': ids.next(),
        'started_at_ms': max(
          _lastSegment(s).endedAtMs!,
          atMilliseconds ?? now().millisecondsSinceEpoch,
        ),
      });
    });
  }

  Future<void> stopStudy({int? atMilliseconds}) async {
    final current = runningSession!;
    final segment = _lastSegment(current);
    final requestedEnd = atMilliseconds ?? now().millisecondsSinceEpoch;
    final end = current.status == 'paused'
        ? segment.endedAtMs!
        : max(segment.startedAtMs, min(requestedEnd, _studyDeadline(current)));
    final completedDuration = sessionDuration(current.id, at: end);
    await _perform(() async {
      final s = runningSession!;
      final segment = _lastSegment(s);
      await _write('study_session', s.id, 'session.stop', {
        'segment_id': segment.id,
        'ended_at_ms': end,
      });
    });
    lastCompletedStudyDuration = completedDuration;
    studyDoNotDisturbEnabled = false;
    notifyListeners();
  }

  /// A detached engine means the app process is being torn down. Close the
  /// active segment at the last observable moment so a force-closed task does
  /// not continue accumulating time after the process is gone.
  Future<void> finishStudyForProcessExit() async {
    await checkpointStudyProgress();
    if (runningSession == null || busy) return;
    await stopStudy();
  }

  int _studyDeadline(StudySession session) {
    final closedDuration = segments
        .where((s) => s.sessionId == session.id && s.endedAtMs != null)
        .fold<int>(0, (sum, s) => sum + max(0, s.endedAtMs! - s.startedAtMs));
    return _lastSegment(session).startedAtMs +
        max(0, maxStudyDuration.inMilliseconds - closedDuration);
  }

  int _segmentEnd(StudySessionSegment segment, int at) {
    if (segment.endedAtMs != null) return segment.endedAtMs!;
    final session = sessions
        .where((s) => s.id == segment.sessionId)
        .firstOrNull;
    if (session == null || session.ownerDeviceId != identity.deviceId) {
      return at;
    }
    return min(at, _studyDeadline(session));
  }

  /// Persist only locally, so a killed process cannot add time on next launch.
  DateTime? _lastStudyCheckpointAt;
  String? _lastStudyCheckpointSessionId;
  Future<void> checkpointStudyProgress({bool force = true}) async {
    final current = runningSession;
    if (current == null) {
      if (!force) return;
      await (database.delete(
        database.localStudyCheckpoints,
      )..where((row) => row.deviceId.equals(identity.deviceId))).go();
      _lastStudyCheckpointAt = null;
      _lastStudyCheckpointSessionId = null;
      return;
    }
    final observedAt = now();
    final previousAt = _lastStudyCheckpointAt;
    // UI ticks still run every second; only the durable heartbeat is throttled.
    // Commands and lifecycle changes force a save through the default argument.
    if (!force &&
        _lastStudyCheckpointSessionId == current.id &&
        previousAt != null &&
        !observedAt.isBefore(previousAt) &&
        observedAt.difference(previousAt) < studyCheckpointInterval) {
      return;
    }
    await database
        .into(database.localStudyCheckpoints)
        .insertOnConflictUpdate(
          LocalStudyCheckpointsCompanion.insert(
            deviceId: identity.deviceId,
            sessionId: current.id,
            observedAtMs: observedAt.millisecondsSinceEpoch,
          ),
        );
    _lastStudyCheckpointAt = observedAt;
    _lastStudyCheckpointSessionId = current.id;
  }

  Future<void> _recoverInterruptedStudy() async {
    final current = runningSession;
    if (current == null) return;
    final checkpoint =
        await (database.select(database.localStudyCheckpoints)
              ..where((row) => row.deviceId.equals(identity.deviceId)))
            .getSingleOrNull();
    // Older installs have no checkpoint: never invent time after their last
    // observable segment boundary.
    final end = checkpoint?.sessionId == current.id
        ? checkpoint!.observedAtMs
        : _lastSegment(current).startedAtMs;
    await stopStudy(atMilliseconds: min(end, now().millisecondsSinceEpoch));
  }

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
              _segmentEnd(s, at ?? now().millisecondsSinceEpoch) -
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
                min(to, _segmentEnd(s, now().millisecondsSinceEpoch)) -
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
    segments: segments
        .map(
          (segment) => segment.endedAtMs != null
              ? segment
              : segment.copyWith(
                  endedAtMs: Value(
                    _segmentEnd(segment, now().millisecondsSinceEpoch),
                  ),
                ),
        )
        .toList(),
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
