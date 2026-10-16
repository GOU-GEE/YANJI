import 'package:flutter/material.dart';

import 'yanji_motion.dart';

class TaskCompletionCheckbox extends StatefulWidget {
  const TaskCompletionCheckbox({
    super.key,
    required this.value,
    required this.checkboxKey,
    required this.label,
    required this.onChanged,
  });
  final bool value;
  final Key checkboxKey;
  final String label;
  final ValueChanged<bool?>? onChanged;
  @override
  State<TaskCompletionCheckbox> createState() => _TaskCompletionCheckboxState();
}

class _TaskCompletionCheckboxState extends State<TaskCompletionCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: YanJiMotion.duration,
    value: 1,
  );
  @override
  void didUpdateWidget(TaskCompletionCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !YanJiMotion.reduced(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (YanJiMotion.reduced(context)) {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    child: Checkbox(
      key: widget.checkboxKey,
      value: widget.value,
      semanticLabel: widget.label,
      onChanged: widget.onChanged,
    ),
    builder: (context, child) => Transform.scale(
      scale: YanJiMotion.reduced(context)
          ? 1
          : 1 + .10 * (1 - (2 * _pulse.value - 1).abs()),
      child: child,
    ),
  );
}

class TaskCompletionTitle extends StatelessWidget {
  const TaskCompletionTitle({
    super.key,
    required this.title,
    required this.completed,
  });
  final String title;
  final bool completed;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.titleMedium ?? const TextStyle();
    final muted = theme.colorScheme.onSurfaceVariant;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: completed ? 1 : 0),
      duration: YanJiMotion.durationOf(context),
      curve: YanJiMotion.curve,
      builder: (context, progress, _) {
        final style = base.copyWith(
          color: Color.lerp(
            base.color ?? theme.colorScheme.onSurface,
            muted,
            progress,
          ),
        );
        return CustomPaint(
          foregroundPainter: _TaskStrike(
            title,
            style,
            Directionality.of(context),
            MediaQuery.textScalerOf(context),
            progress,
            muted,
          ),
          child: Text(title, style: style),
        );
      },
    );
  }
}

class _TaskStrike extends CustomPainter {
  _TaskStrike(
    this.title,
    this.style,
    this.direction,
    this.scaler,
    this.progress,
    this.color,
  );
  final String title;
  final TextStyle style;
  final TextDirection direction;
  final TextScaler scaler;
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final text = TextPainter(
      text: TextSpan(text: title, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: size.width);
    final pen = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final line in text.computeLineMetrics()) {
      final y = line.baseline - line.ascent * .32;
      final start = direction == TextDirection.rtl
          ? line.left + line.width
          : line.left;
      final end =
          start +
          line.width * progress * (direction == TextDirection.rtl ? -1 : 1);
      canvas.drawLine(Offset(start, y), Offset(end, y), pen);
    }
    text.dispose();
  }

  @override
  bool shouldRepaint(covariant _TaskStrike oldDelegate) =>
      title != oldDelegate.title ||
      style != oldDelegate.style ||
      direction != oldDelegate.direction ||
      scaler != oldDelegate.scaler ||
      progress != oldDelegate.progress ||
      color != oldDelegate.color;
}
