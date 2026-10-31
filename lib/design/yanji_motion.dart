import 'package:flutter/material.dart';

/// Short, finite transitions. Business state never waits for these animations.
abstract final class YanJiMotion {
  static const duration = Duration(milliseconds: 180);
  static const curve = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  static Duration durationOf(BuildContext context) =>
      reduced(context) ? Duration.zero : duration;
}

/// Only changes of [identity] animate; ordinary rebuilds keep the child steady.
class MotionSwap extends StatelessWidget {
  const MotionSwap({
    super.key,
    required this.identity,
    required this.child,
    this.alignment = Alignment.centerLeft,
    this.direction = 0,
    this.fill = false,
  });
  final Object? identity;
  final Widget child;
  final Alignment alignment;
  final double direction;

  /// Full-screen and overlay children require bounded height during exit.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    if (YanJiMotion.reduced(context)) return child;
    final currentKey = ValueKey(identity);
    return AnimatedSize(
      duration: YanJiMotion.duration,
      curve: YanJiMotion.curve,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: YanJiMotion.duration,
        switchInCurve: YanJiMotion.curve,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: alignment,
          children: [
            for (final outgoing in previous)
              if (fill)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(child: outgoing),
                  ),
                )
              else
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: ExcludeSemantics(child: outgoing),
                  ),
                ),
            ?current,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(direction * .025, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: currentKey, child: child),
      ),
    );
  }
}

/// Expands optional sections without retaining interactive outgoing content.
class MotionSection extends StatelessWidget {
  const MotionSection({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: YanJiMotion.durationOf(context),
    curve: YanJiMotion.curve,
    alignment: Alignment.topCenter,
    child: child,
  );
}

/// Keeps rows keyed by entity, animating membership changes only.
class MotionList extends StatefulWidget {
  const MotionList({super.key, required this.children});
  final List<Widget> children;

  @override
  State<MotionList> createState() => _MotionListState();
}

class _MotionListState extends State<MotionList> {
  var _list = GlobalKey<AnimatedListState>();
  // This embedded list is scrolled by its enclosing page. Do not read or write
  // the enclosing ExpansionTile's boolean PageStorage state as a scroll offset.
  final _scrollController = ScrollController(keepScrollOffset: false);
  bool? _reduced;
  late List<Widget> _rows;

  @override
  void initState() {
    super.initState();
    _rows = List.of(widget.children);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = YanJiMotion.reduced(context);
    if (_reduced != null && reduced != _reduced) {
      // Replace the list to cancel pending transitions when system preferences change.
      _list = GlobalKey<AnimatedListState>();
      _rows = List.of(widget.children);
    }
    _reduced = reduced;
  }

  @override
  void didUpdateWidget(MotionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final duration = YanJiMotion.durationOf(context);
    for (var i = _rows.length - 1; i >= 0; i--) {
      if (!widget.children.any((row) => row.key == _rows[i].key)) {
        final removed = _rows.removeAt(i);
        _list.currentState?.removeItem(
          i,
          (context, animation) => IgnorePointer(
            child: ExcludeSemantics(child: _transition(removed, animation)),
          ),
          duration: duration,
        );
      }
    }
    for (var i = 0; i < widget.children.length; i++) {
      final row = widget.children[i];
      if (i < _rows.length && _rows[i].key == row.key) {
        _rows[i] = row;
        continue;
      }
      final previous = _rows.indexWhere((entry) => entry.key == row.key);
      if (previous >= 0) {
        // A reorder relocates the existing row without showing stale actions.
        _rows.removeAt(previous);
        _list.currentState?.removeItem(
          previous,
          (_, animation) => const SizedBox.shrink(),
          duration: Duration.zero,
        );
      }
      _rows.insert(i, row);
      _list.currentState?.insertItem(i, duration: duration);
    }
  }

  Widget _transition(Widget child, Animation<double> animation) {
    final curved = animation.drive(CurveTween(curve: YanJiMotion.curve));
    return SizeTransition(
      sizeFactor: curved,
      axisAlignment: -1,
      child: FadeTransition(opacity: curved, child: child),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedList(
    key: _list,
    controller: _scrollController,
    initialItemCount: _rows.length,
    shrinkWrap: true,
    primary: false,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    itemBuilder: (context, index, animation) =>
        _transition(_rows[index], animation),
  );
}
