import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class DonutLabelCandidate {
  const DonutLabelCandidate({
    required this.index,
    required this.anchor,
    required this.size,
    required this.isLeft,
  });
  final int index;
  final Offset anchor;
  final Size size;
  final bool isLeft;
}

class DonutLabelPosition {
  const DonutLabelPosition({required this.candidate, required this.rect});
  final DonutLabelCandidate candidate;
  final Rect rect;
}

List<DonutLabelPosition> layoutDonutLabels({
  required List<DonutLabelCandidate> candidates,
  required Size bounds,
  required Rect exclusionRect,
  double gap = 8,
  double horizontalGap = 12,
  double edgeInset = 8,
}) {
  final result = <DonutLabelPosition>[];
  for (final isLeft in [true, false]) {
    final side = candidates.where((c) => c.isLeft == isLeft).toList()
      ..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
    if (side.isEmpty) continue;
    final tops = <double>[];
    for (var i = 0; i < side.length; i++) {
      final desired = side[i].anchor.dy - side[i].size.height / 2;
      final minimum = i == 0
          ? edgeInset
          : tops[i - 1] + side[i - 1].size.height + gap;
      tops.add(math.max(desired, minimum));
    }
    for (var i = side.length - 1; i >= 0; i--) {
      final maximum = i == side.length - 1
          ? bounds.height - edgeInset - side[i].size.height
          : tops[i + 1] - gap - side[i].size.height;
      tops[i] = math.min(tops[i], maximum);
    }
    for (var i = 1; i < side.length; i++) {
      tops[i] = math.max(tops[i], tops[i - 1] + side[i - 1].size.height + gap);
    }
    for (var i = 0; i < side.length; i++) {
      final c = side[i];
      final top = tops[i];
      final bottom = top + c.size.height;
      final center = exclusionRect.center;
      final radius = exclusionRect.shortestSide / 2;
      final nearestY = top <= center.dy && bottom >= center.dy
          ? 0.0
          : math.min((top - center.dy).abs(), (bottom - center.dy).abs());
      // Find the widest point of the circle across the label's complete
      // vertical span. This keeps every corner outside the ring while allowing
      // labels near 12/6 o'clock to move substantially closer to it.
      final halfWidth = nearestY >= radius
          ? 0.0
          : math.sqrt(radius * radius - nearestY * nearestY);
      final circleEdge = c.isLeft
          ? center.dx - halfWidth
          : center.dx + halfWidth;
      // Never place the label inward from its own slice anchor: the leader can
      // then travel monotonically away from the donut without cutting through it.
      final localEdge = c.isLeft
          ? math.min(circleEdge, c.anchor.dx)
          : math.max(circleEdge, c.anchor.dx);
      final rawX = c.isLeft
          ? localEdge - horizontalGap - c.size.width
          : localEdge + horizontalGap;
      final x = rawX.clamp(edgeInset, bounds.width - edgeInset - c.size.width);
      result.add(
        DonutLabelPosition(candidate: c, rect: Offset(x, tops[i]) & c.size),
      );
    }
  }
  return result;
}
