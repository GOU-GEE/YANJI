import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

import '../application/study_app_controller.dart';
import '../application/study_statistics.dart';
import '../design/yanji_theme.dart';
import 'donut_label_layout.dart';
import 'shared.dart';

const weekLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

class WeekTrendChart extends StatefulWidget {
  const WeekTrendChart({super.key, required this.days, required this.values});
  final List<DateTime> days;
  final List<int?> values;
  @override
  State<WeekTrendChart> createState() => _WeekTrendChartState();
}

class _WeekTrendChartState extends State<WeekTrendChart> {
  int selected = -1;
  void select(int index) => setState(() => selected = index.clamp(0, 6));
  @override
  void didUpdateWidget(WeekTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days.first != widget.days.first) {
      selected = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maximum = widget.values.whereType<int>().fold(0, math.max);
    final step = maximum < 3600000 ? 900000 : 3600000;
    final ceiling = math.max(step, (maximum / step).ceil() * step);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: YanJiChartTokens.trendHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final value in [ceiling, ceiling ~/ 2, 0])
                  Text(
                    value == 0
                        ? '0'
                        : value < 3600000
                        ? '${(value / 60000).toStringAsFixed(value % 60000 == 0 ? 0 : 1)}m'
                        : '${(value / 3600000).toStringAsFixed(value % 3600000 == 0 ? 0 : 1)}h',
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Focus(
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    select(selected + 1);
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    select(selected - 1);
                  } else {
                    return KeyEventResult.ignored;
                  }
                  return KeyEventResult.handled;
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    void touch(Offset position) {
                      final width = constraints.maxWidth - YanJiSpacing.xxl;
                      select(
                        ((position.dx - YanJiSpacing.lg) / width * 6).round(),
                      );
                    }

                    return GestureDetector(
                      key: const Key('week-trend-touch'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => touch(details.localPosition),
                      onHorizontalDragUpdate: (details) =>
                          touch(details.localPosition),
                      child: SizedBox(
                        height: YanJiChartTokens.trendHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _TrendPainter(
                                  values: widget.values,
                                  labels: List.generate(
                                    7,
                                    (i) =>
                                        '${weekLabels[i]} ${calendarDate(widget.days[i])}，${widget.values[i] == null ? '尚未到来' : exactStudyDuration(widget.values[i]!)}',
                                  ),
                                  ceiling: ceiling,
                                  selected: selected,
                                  primary: colors.primary,
                                  border: colors.outlineVariant,
                                  surface: colors.surface,
                                  onSelect: select,
                                ),
                              ),
                            ),
                            if (selected >= 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomSingleChildLayout(
                                    delegate: ChartBubbleLayout(
                                      Offset(
                                        24 +
                                            (constraints.maxWidth - 48) *
                                                selected /
                                                6,
                                        16 +
                                            (YanJiChartTokens.trendHeight -
                                                    32) *
                                                (1 -
                                                    (widget.values[selected] ??
                                                            0) /
                                                        ceiling),
                                      ),
                                    ),
                                    child: ChartBubble(
                                      text:
                                          '${weekLabels[selected]} · ${calendarDate(widget.days[selected])}\n${widget.values[selected] == null ? '尚未到来' : exactStudyDuration(widget.values[selected]!)}',
                                      textKey: const Key('week-tooltip'),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: List.generate(
                  7,
                  (i) => Expanded(
                    child: Text(
                      weekLabels[i],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: i == selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.labels,
    required this.ceiling,
    required this.selected,
    required this.primary,
    required this.border,
    required this.surface,
    required this.onSelect,
  });
  final List<int?> values;
  final List<String> labels;
  final int ceiling, selected;
  final Color primary, border, surface;
  final ValueChanged<int> onSelect;
  Offset point(Size size, int i) => Offset(
    YanJiSpacing.lg + (size.width - YanJiSpacing.xxl) * i / 6,
    YanJiSpacing.md +
        (size.height - YanJiSpacing.xl) * (1 - (values[i] ?? 0) / ceiling),
  );
  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - YanJiSpacing.md;
    final grid = Paint()
      ..color = border
      ..strokeWidth = 1;
    for (final fraction in [0.0, .5, 1.0]) {
      final y = YanJiSpacing.md + (size.height - YanJiSpacing.xl) * fraction;
      canvas.drawLine(
        Offset(YanJiSpacing.lg, y),
        Offset(size.width - YanJiSpacing.lg, y),
        grid,
      );
    }
    final count = values.takeWhile((v) => v != null).length;
    if (count == 0) return;
    final line = Path()..moveTo(point(size, 0).dx, point(size, 0).dy);
    for (var i = 1; i < count; i++) {
      final a = point(size, i - 1), b = point(size, i);
      final bend = (b.dx - a.dx) * YanJiChartTokens.curveTension;
      // Both controls lie inside the adjacent values' range: no fabricated peaks.
      line.cubicTo(a.dx + bend, a.dy, b.dx - bend, b.dy, b.dx, b.dy);
    }
    final area = Path.from(line)
      ..lineTo(point(size, count - 1).dx, baseline)
      ..lineTo(point(size, 0).dx, baseline)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = primary.withValues(alpha: YanJiChartTokens.areaOpacity),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = YanJiChartTokens.lineWidth,
    );
    if (selected >= 0 && values[selected] != null) {
      final p = point(size, selected);
      canvas.drawLine(
        Offset(p.dx, YanJiSpacing.md),
        Offset(p.dx, baseline),
        Paint()
          ..color = primary.withValues(alpha: .35)
          ..strokeWidth = 1,
      );
    }
    for (var i = 0; i < count; i++) {
      final p = point(size, i);
      final radius = i == selected
          ? YanJiChartTokens.selectedRadius
          : YanJiChartTokens.pointRadius;
      canvas.drawCircle(p, radius + 2, Paint()..color = surface);
      canvas.drawCircle(p, radius, Paint()..color = primary);
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => List.generate(7, (i) {
        final p = point(size, i);
        return CustomPainterSemantics(
          rect: Rect.fromCenter(
            center: Offset(
              p.dx,
              p.dy.clamp(YanJiSpacing.lg, size.height - YanJiSpacing.lg),
            ),
            width: YanJiLayout.touch,
            height: YanJiLayout.touch,
          ),
          properties: SemanticsProperties(
            sortKey: OrdinalSortKey(i.toDouble()),
            label: labels[i],
            button: true,
            selected: selected == i,
            textDirection: TextDirection.ltr,
            onTap: () => onSelect(i),
          ),
        );
      });
  @override
  bool shouldRebuildSemantics(covariant _TrendPainter oldDelegate) => true;
  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}

class SubjectSlice {
  const SubjectSlice(this.id, this.name, this.duration, this.color);
  final String id, name;
  final int duration;
  final Color color;
}

String studyPercentage(int value, int total) {
  if (value == 0 || total == 0) return '0%';
  final percentage = value / total * 100;
  return percentage < .1 ? '<0.1%' : '${percentage.toStringAsFixed(1)}%';
}

class ChartBubble extends StatelessWidget {
  const ChartBubble({super.key, required this.text, this.textKey});
  final String text;
  final Key? textKey;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          key: textKey,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    ),
  );
}

class ChartBubbleLayout extends SingleChildLayoutDelegate {
  ChartBubbleLayout(this.point);
  final Offset point;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth - 8,
        maxHeight: constraints.maxHeight,
      );
  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    (point.dx + 10).clamp(4, math.max(4, size.width - childSize.width - 4)),
    (point.dy - childSize.height - 10).clamp(
      0,
      math.max(0, size.height - childSize.height),
    ),
  );
  @override
  bool shouldRelayout(covariant ChartBubbleLayout oldDelegate) =>
      point != oldDelegate.point;
}

class SubjectDonut extends StatefulWidget {
  const SubjectDonut({super.key, required this.slices, required this.total});
  final List<SubjectSlice> slices;
  final int total;

  @override
  State<SubjectDonut> createState() => _SubjectDonutState();
}

class _SubjectDonutState extends State<SubjectDonut> {
  String? hoveredId;
  String? tappedId;
  Offset? hoveredPosition;
  Offset? tappedPosition;

  void setHovered(String? id, Offset? position) {
    if (hoveredId == id && hoveredPosition == position) return;
    setState(() {
      hoveredId = id;
      hoveredPosition = id == null ? null : position;
    });
  }

  void setTapped(String? id, Offset? position) {
    setState(() {
      tappedId = id;
      tappedPosition = id == null ? null : position;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final slices = widget.slices;
      final total = widget.total;
      final width = constraints.maxWidth;
      final visible = slices.where((s) => s.duration > 0).toList();
      const edgeInset = 8.0;
      const labelClearance = 12.0;
      // Leave real columns on both sides for labels. The former 55% donut and
      // over-wide labels competed for the same horizontal pixels.
      final diameter = math.min(220.0, math.max(104.0, width * .46));
      final radius = diameter / 2;
      final maxLabelWidth = math.min(
        132.0,
        math.max(40.0, (width - diameter) / 2 - labelClearance - edgeInset),
      );
      final textStyle = Theme.of(context).textTheme.labelSmall!;
      final mutedStyle = textStyle.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
      final textScaler = MediaQuery.textScalerOf(context);
      final labelData = <({int index, Offset direction, Size size})>[];
      var angle = -math.pi / 2;
      for (var i = 0; i < visible.length; i++) {
        final slice = visible[i];
        final sweep = slice.duration / total * math.pi * 2;
        final mid = angle + sweep / 2;
        final direction = Offset(math.cos(mid), math.sin(mid));
        final painter = TextPainter(
          text: TextSpan(
            style: textStyle,
            text: '${slice.name}\n',
            children: [
              TextSpan(text: durationLabel(slice.duration), style: mutedStyle),
            ],
          ),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
          textAlign: direction.dx < 0 ? TextAlign.right : TextAlign.left,
        )..layout(maxWidth: maxLabelWidth);
        labelData.add((index: i, direction: direction, size: painter.size));
        angle += sweep;
      }

      double labelsHeight(bool isLeft) {
        final labels = labelData
            .where((data) => (data.direction.dx < 0) == isLeft)
            .toList();
        if (labels.isEmpty) return 0;
        return labels.fold<double>(0, (sum, data) => sum + data.size.height) +
            (labels.length - 1) * 8 +
            edgeInset * 2;
      }

      // A fixed-height plot cannot satisfy non-overlap when many subjects are
      // visible or accessibility text scaling is enabled.
      final height = math.max(
        diameter + 96,
        math.max(labelsHeight(true), labelsHeight(false)),
      );
      final center = Offset(width / 2, height / 2);
      final exclusionRect = Rect.fromCircle(center: center, radius: radius);
      String? sliceAt(Offset point) {
        if (total <= 0) return null;
        final distance = (point - center).distance;
        if (distance < radius - YanJiChartTokens.ringWidth - 8 ||
            distance > radius + 8) {
          return null;
        }
        var angle =
            math.atan2(point.dy - center.dy, point.dx - center.dx) +
            math.pi / 2;
        if (angle < 0) angle += math.pi * 2;
        var end = 0.0;
        for (final slice in visible) {
          end += slice.duration / total * math.pi * 2;
          if (angle <= end) return slice.id;
        }
        return visible.lastOrNull?.id;
      }

      final selectedId = hoveredId ?? tappedId;
      final selectedPosition = hoveredId != null
          ? hoveredPosition
          : tappedPosition;
      final selectedSlice = visible
          .where((slice) => slice.id == selectedId)
          .firstOrNull;
      final candidates = [
        for (final data in labelData)
          DonutLabelCandidate(
            index: data.index,
            anchor: center + data.direction * radius,
            size: data.size,
            isLeft: data.direction.dx < 0,
          ),
      ];
      final positions = layoutDonutLabels(
        candidates: candidates,
        bounds: Size(width, height),
        exclusionRect: exclusionRect,
        horizontalGap: labelClearance,
        edgeInset: edgeInset,
      );
      final leaders = <(Offset, Offset, Color)>[];
      final labels = <Widget>[];
      for (final position in positions) {
        final slice = visible[position.candidate.index];
        final rect = position.rect;
        final labelSelected = selectedSlice?.id == slice.id;
        final direction = position.candidate.isLeft ? -1.0 : 1.0;
        // Start and end with a small air gap. The curve starts horizontally
        // away from the circle and remains in the label corridor.
        final start = Offset(
          position.candidate.anchor.dx + direction * 3,
          position.candidate.anchor.dy,
        );
        final end = Offset(
          position.candidate.isLeft ? rect.right + 4 : rect.left - 4,
          rect.center.dy,
        );
        leaders.add((start, end, slice.color));
        labels.add(
          Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: () {
                HapticFeedback.selectionClick();
                setTapped(
                  labelSelected ? null : slice.id,
                  labelSelected ? null : position.candidate.anchor,
                );
              },
              child: Semantics(
                key: ValueKey('donut-label-action-${slice.id}'),
                label: '${slice.name}，${exactStudyDuration(slice.duration)}',
                button: true,
                selected: labelSelected,
                onTap: () => setTapped(
                  labelSelected ? null : slice.id,
                  labelSelected ? null : position.candidate.anchor,
                ),
                child: ExcludeSemantics(
                  child: Text.rich(
                    TextSpan(
                      style: textStyle,
                      text: '${slice.name}\n',
                      children: [
                        TextSpan(
                          text: durationLabel(slice.duration),
                          style: mutedStyle,
                        ),
                      ],
                    ),
                    key: ValueKey('donut-label-${slice.id}'),
                    textAlign: position.candidate.isLeft
                        ? TextAlign.right
                        : TextAlign.left,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      final chart = SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _LeaderPainter(leaders)),
            ),
            Positioned(
              left: center.dx - diameter / 2,
              top: center.dy - diameter / 2,
              width: diameter,
              height: diameter,
              child: SizedBox(
                key: const Key('subject-donut'),
                child: CustomPaint(
                  painter: _DonutPainter(
                    slices,
                    total,
                    selectedSlice?.id,
                    Theme.of(context).colorScheme.outlineVariant,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: diameter - 52,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const YanJiCaption('总学习时间'),
                            const SizedBox(height: 4),
                            Text(
                              durationLabel(total),
                              key: const Key('donut-total'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...labels,
            if (selectedSlice != null && selectedPosition != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomSingleChildLayout(
                    delegate: ChartBubbleLayout(selectedPosition),
                    child: ChartBubble(
                      textKey: const Key('subject-tooltip'),
                      text:
                          '${selectedSlice.name}\n'
                          '学习时间 ${durationLabel(selectedSlice.duration)}\n'
                          '占比 ${studyPercentage(selectedSlice.duration, total)}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

      return MouseRegion(
        onHover: (event) =>
            setHovered(sliceAt(event.localPosition), event.localPosition),
        onExit: (_) => setHovered(null, null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final id = sliceAt(details.localPosition);
            setTapped(id, id == null ? null : details.localPosition);
          },
          child: chart,
        ),
      );
    },
  );
}

class _LeaderPainter extends CustomPainter {
  _LeaderPainter(this.lines);
  final List<(Offset, Offset, Color)> lines;
  @override
  void paint(Canvas canvas, Size size) {
    for (final (start, end, color) in lines) {
      final dx = end.dx - start.dx;
      // Anchors and label ports retain the same vertical order. A monotonic
      // cubic keeps that order while avoiding the long fixed-column detour.
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx + dx * .42,
            start.dy,
            start.dx + dx * .78,
            end.dy,
            end.dx,
            end.dy,
          ),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderPainter oldDelegate) => true;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.total, this.selected, this.track);
  final List<SubjectSlice> slices;
  final int total;
  final String? selected;
  final Color track;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(YanJiChartTokens.ringWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = YanJiChartTokens.ringWidth;
    if (total == 0) {
      canvas.drawArc(ring, 0, math.pi * 2, false, paint..color = track);
      return;
    }
    final arcs = <({SubjectSlice slice, double start, double sweep})>[];
    var start = -math.pi / 2;
    for (final slice in slices.where((s) => s.duration > 0)) {
      final sweep = slice.duration / total * math.pi * 2;
      arcs.add((slice: slice, start: start, sweep: sweep));
      canvas.drawArc(ring, start, sweep, false, paint..color = slice.color);
      start += sweep;
    }
    final selectedArc = arcs
        .where((arc) => arc.slice.id == selected)
        .firstOrNull;
    if (selectedArc != null) {
      canvas.drawArc(
        ring.inflate(3),
        selectedArc.start,
        selectedArc.sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = YanJiChartTokens.ringWidth + 4
          ..color = selectedArc.slice.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
