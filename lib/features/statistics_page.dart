import 'dart:async';

import '../sync/files/automatic_sync_controller.dart';
import '../sync/files/operation_file_exchange.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/yanji_motion.dart';

import '../design/glass/glass_controls.dart';
import '../design/glass/glass_segmented_control.dart';
import '../design/glass/glass_date_range_picker.dart';

import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import 'study_heatmap.dart';
import '../design/yanji_theme.dart';
import 'shared.dart';
import 'profile_sync_status.dart';
import 'statistics_charts.dart';
import 'target_goal.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage(this.app, {super.key});
  final StudyAppController app;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with WidgetsBindingObserver {
  _SubjectRange subjectRange = _SubjectRange.day;
  DateTimeRange? customRange;
  bool showChildren = false;
  Timer? refresh;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh display only: no counter or statistics writes.
    refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app, data = app.statistics;
    final theme = Theme.of(context);
    final firstRecordedDay = data.daily.keys.isEmpty
        ? null
        : data.daily.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    final lastRecordedDay = data.daily.keys.isEmpty
        ? null
        : data.daily.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    String period(DateTime from, DateTime to) =>
        '${calendarDate(from)} 至 ${calendarDate(to)}';
    final rangeCaption = switch (subjectRange) {
      _SubjectRange.day => calendarDate(data.today),
      _SubjectRange.week => period(data.monday, data.today),
      _SubjectRange.month => period(
        DateTime.utc(data.today.year, data.today.month),
        data.today,
      ),
      _SubjectRange.total =>
        firstRecordedDay == null
            ? '暂无学习记录'
            : period(firstRecordedDay, lastRecordedDay!),
      _SubjectRange.custom =>
        customRange == null
            ? '请选择日期区间'
            : period(customRange!.start, customRange!.end),
    };
    final dateSlotHeight = MediaQuery.textScalerOf(context).scale(24);
    final rawSubjectValues = switch (subjectRange) {
      _SubjectRange.day => data.dayBySubject,
      _SubjectRange.week => data.weekBySubject,
      _SubjectRange.month => data.bySubjectIn(
        DateTime(data.today.year, data.today.month),
        data.today,
      ),
      _SubjectRange.total => data.bySubject,
      _SubjectRange.custom =>
        customRange == null
            ? <String, int>{}
            : data.bySubjectIn(customRange!.start, customRange!.end),
    };
    // In summary mode, roll child-subject records up to their parent so the
    // displayed slices account for the complete study total.
    final subjectValues = <String, int>{};
    for (final entry in rawSubjectValues.entries) {
      final subject = app.subject(entry.key);
      final displayId = !showChildren && subject?.parentSubjectId != null
          ? subject!.parentSubjectId!
          : entry.key;
      subjectValues.update(
        displayId,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    final visible = app.subjects.where(app.isSubjectVisible).toList();
    final parents = visible.where((s) => s.parentSubjectId == null).toList();
    final childrenByParent = <String, List<dynamic>>{};
    for (final s in visible.where((s) => s.parentSubjectId != null)) {
      childrenByParent.putIfAbsent(s.parentSubjectId!, () => []).add(s);
    }
    final displaySubjects = showChildren
        ? visible
              .where(
                (s) =>
                    subjectValues[s.id] != null &&
                    (s.parentSubjectId != null ||
                        childrenByParent[s.id]?.isNotEmpty != true),
              )
              .toList()
        : parents
              .where(
                (s) =>
                    subjectValues[s.id] != null ||
                    childrenByParent[s.id]?.isNotEmpty == true,
              )
              .toList();
    final slices = displaySubjects.map((s) => s.id).toList().map((id) {
      final index = displaySubjects.indexWhere((s) => s.id == id);
      return SubjectSlice(
        id,
        app.subject(id)?.name ?? '已移除科目',
        subjectValues[id] ?? 0,
        YanJiChartTokens.subjectAt(index, theme.brightness),
      );
    }).toList();
    // When showing fine-grained subjects, the donut total must use the same
    // slice set. Otherwise parent-subject time leaves the ring incomplete.
    final donutTotal = slices.fold<int>(
      0,
      (sum, slice) => sum + slice.duration,
    );
    return PageBody(
      title: '数据',
      showTitle: false,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: YanJiSpacing.lg,
          runSpacing: YanJiSpacing.lg,
          children: [
            _Stat('平均每日', durationLabel(data.averagePerDay)),
            _Stat('累计学习', durationLabel(data.total)),
            _Stat('学习天数', '${data.learningDays} 天'),
          ],
        ),
        const SizedBox(height: YanJiSpacing.xl),
        YanJiPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('本周学习', style: theme.textTheme.titleLarge),
                        Text(
                          '轻触或拖动查看',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Column(
                      crossAxisAlignment: YanJiLayout.stacked(context)
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(
                          durationLabel(data.weekTotal),
                          key: const Key('week-total'),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: YanJiSpacing.lg),
              WeekTrendChart(days: data.weekDays, values: data.weekValues),
            ],
          ),
        ),
        const SizedBox(height: YanJiSpacing.xl),
        Row(
          children: [
            Expanded(child: Text('各科学习时间', style: theme.textTheme.titleLarge)),
            GlassOutlinedButton(
              onPressed: () => setState(() => showChildren = !showChildren),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
                textStyle: theme.textTheme.labelSmall,
              ),
              child: Text(showChildren ? '查看总和' : '查看细分'),
            ),
          ],
        ),
        const SizedBox(height: YanJiSpacing.md),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: SizedBox(
              key: const Key('subject-range'),
              height: 42,
              child: GlassSegmentedControl(
                labels: const ['日', '周', '月', '总', '自定义'],
                selected: subjectRange.index,
                onSelected: (index) async {
                  final choice = _SubjectRange.values[index];
                  if (choice == _SubjectRange.custom) {
                    final today = DateTime(
                      data.today.year,
                      data.today.month,
                      data.today.day,
                    );
                    final picked = await showGlassDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: today,
                      initialDateRange:
                          customRange ??
                          DateTimeRange(
                            start: today.subtract(const Duration(days: 6)),
                            end: today,
                          ),
                    );
                    if (picked == null || !context.mounted) return false;
                    setState(() {
                      customRange = picked;
                      subjectRange = choice;
                    });
                    return true;
                  }
                  setState(() => subjectRange = choice);
                  return true;
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          key: const Key('subject-period-slot'),
          height: dateSlotHeight,
          child: Center(
            child: AnimatedSwitcher(
              duration: YanJiMotion.durationOf(context),
              child: Text(
                rangeCaption,
                key: ValueKey(rangeCaption),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        MotionSwap(
          identity: (
            subjectRange,
            showChildren,
            customRange?.start,
            customRange?.end,
            donutTotal == 0,
          ),
          alignment: Alignment.topCenter,
          child: SubjectDonut(
            slices: slices,
            total: donutTotal,
            emptyLabel: switch (subjectRange) {
              _SubjectRange.day => '今天无数据',
              _SubjectRange.week => '本周无数据',
              _SubjectRange.month => '本月无数据',
              _SubjectRange.custom => '此区间无数据',
              _SubjectRange.total => '暂无数据',
            },
          ),
        ),
        SizedBox(height: dateSlotHeight + 8),
        StudyHeatmap(daily: data.daily, today: data.today),
        const SizedBox(height: YanJiSpacing.lg),
      ],
    );
  }
}

enum _SubjectRange { day, week, month, total, custom }

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      YanJiCaption(label),
      const SizedBox(height: YanJiSpacing.xs),
      MotionSwap(
        identity: value,
        child: Text(
          value,
          key: ValueKey('stat-$label'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    ],
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage(
    this.app, {
    super.key,
    required this.onSync,
    this.sync,
    this.syncFeedback,
  });
  final StudyAppController app;
  final Future<void> Function() onSync;
  final AutomaticSyncController? sync;
  final ProfileSyncController? syncFeedback;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileSyncController? _ownedFeedback;
  StudyAppController get app => widget.app;
  AutomaticSyncController? get sync => widget.sync;
  ProfileSyncController get feedback => widget.syncFeedback ?? _ownedFeedback!;

  @override
  void initState() {
    super.initState();
    if (widget.syncFeedback == null) {
      _ownedFeedback = ProfileSyncController()..bind(sync);
    }
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.syncFeedback == null) {
      (_ownedFeedback ??= ProfileSyncController()).bind(sync);
    } else {
      _ownedFeedback?.dispose();
      _ownedFeedback = null;
    }
  }

  @override
  void dispose() {
    _ownedFeedback?.dispose();
    super.dispose();
  }

  String targetSummary() {
    final exam = app.exam;
    final school = exam?.targetSchool?.trim();
    final major = exam?.targetMajor?.trim();
    final score = exam?.targetTotalScoreX100;
    final parts = <String>[
      if (school != null && school.isNotEmpty) school,
      if (major != null && major.isNotEmpty) major,
      if (score != null) '${formatTargetScoreX100(score)}分',
    ];
    return parts.isEmpty ? '把每一天的努力，变成看得见的轨迹。' : '目标：${parts.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) => PageBody(
    title: '我的',
    showTitle: false,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: kDebugMode
                  ? () => context.push('/debug/oppo-fluid-cloud')
                  : null,
              child: Text(
                '研迹 YanJi',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(targetSummary()),
      const SizedBox(height: 32),
      YanjiGlassControl(
        elastic: true,
        elasticity: .35,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: const Icon(Icons.flag_outlined),
          title: const Text('我的目标'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/goal'),
        ),
      ),
      const SizedBox(height: 8),
      YanjiGlassControl(
        elastic: true,
        elasticity: .35,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: const Icon(Icons.book_outlined),
          title: const Text('我的科目'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/subjects'),
        ),
      ),
      const Divider(height: 40),
      Row(
        children: [
          Expanded(
            child: Text(
              '设备与同步',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: YanjiGlassControl(
              radius: 20,
              elastic: true,
              child: IconButton(
                key: const Key('add-device'),
                tooltip: '添加设备',
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  fixedSize: const Size(40, 40),
                  visualDensity: VisualDensity.standard,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add),
                onPressed: app.busy ? null : () => context.push('/device-tree'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: YanJiSpacing.sm),
      ListenableBuilder(
        listenable: Listenable.merge([app, ?sync]),
        builder: (context, _) {
          final devices = app.trustedPeers
              .where(
                (peer) => peer.active && peer.deviceId != app.identity.deviceId,
              )
              .toList();
          if (devices.isEmpty) return const Text('暂无已配对设备');
          return Column(
            children: [
              for (final device in devices)
                Padding(
                  padding: const EdgeInsets.only(bottom: YanJiSpacing.sm),
                  child: YanjiGlassControl(
                    elastic: !app.busy,
                    child: InkWell(
                      key: ValueKey('device-row-${device.deviceId}'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: app.busy
                          ? null
                          : () => editPairedDevice(context, app, device),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: YanJiSpacing.md,
                          vertical: YanJiSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                device.deviceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: YanJiSpacing.sm),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: MotionSwap(
                                  identity: _deviceStatus(device.deviceId),
                                  child: Text(
                                    _deviceStatus(device.deviceId),
                                    textAlign: TextAlign.right,
                                    key: ValueKey(
                                      'device-status-${device.deviceId}',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      ListenableBuilder(
        listenable: app,
        builder: (context, _) => ProfileSyncStatus(
          controller: feedback,
          hasPeers: app.trustedPeers.any(
            (peer) => peer.active && peer.deviceId != app.identity.deviceId,
          ),
          busy: app.busy,
          onSync: widget.onSync,
        ),
      ),
    ],
  );

  String _deviceStatus(String deviceId) {
    if (sync?.pairing.isPairConfirmed(deviceId) == false) {
      return '等待另一端完成配对';
    }
    PeerSyncProgress? progress;
    for (final peer in sync?.peers ?? const <PeerSyncProgress>[]) {
      if (peer.deviceId == deviceId) {
        progress = peer;
        break;
      }
    }
    if (progress == null) return '等待同步';
    final state = progress.confirmed && progress.pending == 0
        ? '已同步'
        : progress.pendingKnown && progress.pending > 0
        ? '待同步 ${progress.pending} 条'
        : '等待设备确认';
    return '$state · ${progress.connected ? "已连接" : "等待连接"}';
  }
}
