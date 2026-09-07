import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import 'study_heatmap.dart';
import '../design/yanji_theme.dart';
import 'shared.dart';
import 'statistics_charts.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage(this.app, {super.key});
  final StudyAppController app;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with WidgetsBindingObserver {
  bool weekly = true;
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
    final rawSubjectValues = weekly ? data.weekBySubject : data.bySubject;
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
                (s) => s.parentSubjectId != null && subjectValues[s.id] != null,
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
    final change = data.weekChange;
    return PageBody(
      title: '数据',
      showTitle: false,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: YanJiSpacing.lg,
          runSpacing: YanJiSpacing.lg,
          children: [
            _Stat('今日学习', durationLabel(data.todayDuration)),
            _Stat('累计学习', durationLabel(data.total)),
            _Stat('连续学习', '${data.currentStreak} 天'),
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
                        if (change != null)
                          Text(
                            '较上周 ${change >= 0 ? '+' : '−'}${change.abs().toStringAsFixed(1)}%',
                            key: const Key('week-change'),
                            style: theme.textTheme.bodySmall,
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
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => setState(() => weekly = !weekly),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(44, 32),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                textStyle: theme.textTheme.labelSmall,
              ),
              child: Text(weekly ? '查看累计' : '查看本周'),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () => setState(() => showChildren = !showChildren),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 32),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                textStyle: theme.textTheme.labelSmall,
              ),
              child: Text(showChildren ? '查看总和' : '查看细分'),
            ),
          ],
        ),
        const SizedBox(height: YanJiSpacing.lg),
        SubjectDonut(slices: slices, total: donutTotal),
        const SizedBox(height: YanJiSpacing.md),
        if (donutTotal == 0)
          YanJiCaption(
            weekly ? '本周还没有学习记录，开始一段专注后再来看看。' : '还没有学习记录，开始第一段学习后，这里会留下你的轨迹。',
          ),
        const SizedBox(height: YanJiSpacing.xl),
        Text('学习积累', style: theme.textTheme.titleLarge),
        const SizedBox(height: YanJiSpacing.md),
        YanJiPanel(
          muted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: YanJiSpacing.lg,
                runSpacing: YanJiSpacing.lg,
                children: [
                  _Stat('学习天数', '${data.learningDays} 天'),
                  _Stat('最长连续学习', '${data.longestStreak} 天'),
                  _Stat('平均每日学习', durationLabel(data.averagePerDay)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: YanJiSpacing.xl),
        StudyHeatmap(daily: data.daily, today: data.today),
        const SizedBox(height: YanJiSpacing.lg),
      ],
    );
  }
}

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
      Text(
        value,
        key: ValueKey('stat-$label'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ],
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage(this.app, {super.key});
  final StudyAppController app;
  @override
  Widget build(BuildContext context) => PageBody(
    title: '我的',
    showTitle: false,
    children: [
      Text('研迹 YanJi', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Text('把每一天的努力，变成看得见的轨迹。'),
      const SizedBox(height: 32),
      const SizedBox(height: 32),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.book_outlined),
        title: const Text('我的科目'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/subjects'),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.devices_outlined),
        title: const Text('添加设备'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/device-tree'),
      ),
      const Divider(height: 40),
      const Text('你的学习记录保存在这台设备上。\n无需登录，也能离线使用。'),
    ],
  );
}
