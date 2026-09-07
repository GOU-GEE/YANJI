import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../application/study_app_controller.dart';
import '../application/study_statistics.dart';
import 'statistics_charts.dart';

// Dates are calendar labels from StudyStatistics, never device-local instants.
const heatmapRowDays = 91;
DateTime heatmapStart(Map<DateTime, int> daily, DateTime today) => daily.entries
    .where((e) => e.value > 0 && !e.key.isAfter(today))
    .fold(
      today,
      (first, entry) => entry.key.isBefore(first) ? entry.key : first,
    );
int heatmapRows(DateTime first, DateTime today) => math.max(
  1,
  (today.difference(first).inDays + 1 + heatmapRowDays - 1) ~/ heatmapRowDays,
);
List<DateTime> heatmapDays(DateTime first, int row) => List.generate(
  heatmapRowDays,
  (i) => first.add(Duration(days: row * heatmapRowDays + i)),
);
int heatmapLevel(int duration) => duration < 3600000
    ? 0
    : duration < 7200000
    ? 1
    : duration < 14400000
    ? 2
    : duration < 21600000
    ? 3
    : 4;

class StudyHeatmap extends StatefulWidget {
  const StudyHeatmap({
    super.key,
    required this.daily,
    required this.today,
    this.fullPage = false,
  });
  final Map<DateTime, int> daily;
  final DateTime today;
  final bool fullPage;
  @override
  State<StudyHeatmap> createState() => _StudyHeatmapState();
}

class _StudyHeatmapState extends State<StudyHeatmap> {
  DateTime? selected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final first = heatmapStart(widget.daily, widget.today);
    final rows = heatmapRows(first, widget.today);
    final palette = List.generate(
      5,
      (i) => i == 0
          ? colors.outlineVariant.withValues(alpha: .45)
          : Color.lerp(
              colors.surface,
              colors.primary,
              [.0, .28, .48, .72, 1.0][i],
            )!,
    );
    Widget legend() => Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 5; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: palette[i],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                ['0–<1h', '≥1h', '≥2h', '≥4h', '≥6h'][i],
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
      ],
    );
    Widget row(int index) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _group(first, index, constraints.maxWidth, palette),
      ),
    );
    if (widget.fullPage) {
      return Scaffold(
        appBar: AppBar(title: const Text('学习热力图')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows + 1,
                itemBuilder: (context, index) => index == 0
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: legend(),
                      )
                    : row(index - 1),
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('学习热力图', style: theme.textTheme.titleLarge)),
            TextButton(
              key: const Key('heatmap-view-all'),
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudyHeatmap(
                    daily: widget.daily,
                    today: widget.today,
                    fullPage: true,
                  ),
                ),
              ),
              child: const Text('查看更多'),
            ),
          ],
        ),
        if (widget.daily.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('第一段学习完成后，这里会留下你的轨迹。'),
          ),
        const SizedBox(height: 12),
        for (var index = 0; index < math.min(2, rows); index++) row(index),
        legend(),
      ],
    );
  }

  Widget _group(DateTime first, int group, double width, List<Color> palette) {
    final days = heatmapDays(first, group);
    final columns = days.length ~/ 7;
    const gutter = 24.0;
    final step = (width - gutter) / columns;
    final cell = math.min(18.0, step - 3);
    final header = math.max(
      28.0,
      MediaQuery.textScalerOf(context).scale(12) * 1.5 + 8,
    );
    final monthLabelWidth = math.min(
      width,
      MediaQuery.textScalerOf(context).scale(40),
    );
    // A partial first week can contain both the starting month and next month.
    // Share one label in that column instead of painting overlapping labels.
    final monthLabels = <int, List<int>>{};
    for (var i = 0; i < days.length; i++) {
      if (days[i].day == 1 || (group == 0 && i == 0)) {
        monthLabels.putIfAbsent(i ~/ 7, () => []).add(days[i].month);
      }
    }
    final height = header + step * 7;
    final selectedIndex = selected == null ? -1 : days.indexOf(selected!);
    void touch(Offset position) {
      final column = ((position.dx - gutter) / step).floor();
      final row = ((position.dy - header) / step).floor();
      if (column < 0 || column >= columns || row < 0 || row > 6) return;
      final day = days[column * 7 + row];
      if (!day.isAfter(widget.today)) {
        setState(() => selected = day);
      }
    }

    return GestureDetector(
      key: ValueKey('heatmap-group-$group'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => touch(d.localPosition),
      onHorizontalDragUpdate: (d) => touch(d.localPosition),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            for (final entry in monthLabels.entries)
              Positioned(
                left:
                    (gutter + entry.key * step + cell / 2 - monthLabelWidth / 2)
                        .clamp(0, width - monthLabelWidth),
                top: 0,
                width: monthLabelWidth,
                child: Text(
                  '${entry.value.join('/')}月',
                  key: ValueKey('heatmap-month-$group-${entry.key}'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            for (final row in [0, 2, 4])
              Positioned(
                left: 0,
                top: header + step * row,
                child: Text(
                  [
                    '一',
                    '二',
                    '三',
                    '四',
                    '五',
                    '六',
                    '日',
                  ][(first.weekday - 1 + row) % 7],
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            for (var i = 0; i < days.length; i++)
              if (days[i] case final day)
                Positioned(
                  left: gutter + (i ~/ 7) * step,
                  top: header + (i % 7) * step,
                  width: cell,
                  height: cell,
                  child: Semantics(
                    button: !day.isAfter(widget.today),
                    selected: day == selected,
                    label:
                        '${calendarDate(day)}，${day.isAfter(widget.today) ? '尚未到来' : exactStudyDuration(widget.daily[day] ?? 0)}',
                    onTap: day.isAfter(widget.today)
                        ? null
                        : () => setState(() => selected = day),
                    child: DecoratedBox(
                      key: ValueKey('heatmap-day-${calendarDate(day)}'),
                      decoration: BoxDecoration(
                        color: day.isAfter(widget.today)
                            ? palette.first.withValues(alpha: .18)
                            : palette[heatmapLevel(widget.daily[day] ?? 0)],
                        border: day == selected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 1.5,
                              )
                            : day.isAfter(widget.today)
                            ? Border.all(
                                color: palette.first.withValues(alpha: .35),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            if (selectedIndex >= 0 && selected != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomSingleChildLayout(
                    delegate: ChartBubbleLayout(
                      Offset(
                        gutter + (selectedIndex ~/ 7) * step,
                        header + (selectedIndex % 7) * step,
                      ),
                    ),
                    child: ChartBubble(
                      text:
                          '${calendarDate(selected!)}\n${exactStudyDuration(widget.daily[selected] ?? 0)}',
                      textKey: const Key('heatmap-tooltip'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
