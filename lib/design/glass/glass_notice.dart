import 'dart:async';

import 'package:flutter/material.dart';

import 'glass_controls.dart';
import 'glass_floating_surface.dart';

/// A short, non-blocking glass notice below the status bar.
abstract final class GlassNotice {
  static OverlayEntry? _active;

  static void show(BuildContext context, String message) {
    message = chineseMessage(message);
    _active
      ?..remove()
      ..dispose();
    final top = MediaQuery.paddingOf(context).top + 10;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        left: 20,
        right: 20,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _NoticeBody(
              message: message,
              onDismiss: () {
                if (_active != entry) return;
                _active = null;
                entry.remove();
                entry.dispose();
              },
            ),
          ),
        ),
      ),
    );
    _active = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  static String chineseMessage(String message) {
    var text = message.replaceFirst(
      RegExp(
        r'^(?:Bad state:|StateError:|Exception:|SocketException:|FormatException:)\s*',
      ),
      '',
    );
    for (final entry in {
      'Workspace Genesis': '学习空间身份记录',
      'Genesis': '身份记录',
      'Wi-Fi': '无线网络',
      'TLS': '安全连接',
      'CBOR': '同步数据',
    }.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      return '操作暂未完成，请稍后重试。已有记录保留。';
    }
    text = text.replaceAll(RegExp(r'[A-Za-z][A-Za-z0-9_.:/-]*'), '').trim();
    return text.replaceAll(RegExp(r'[:：]\s*$'), '');
  }
}

class _NoticeBody extends StatefulWidget {
  const _NoticeBody({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  State<_NoticeBody> createState() => _NoticeBodyState();
}

class _NoticeBodyState extends State<_NoticeBody>
    with SingleTickerProviderStateMixin {
  static const double _maxDownwardPull = 14;
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 390),
    reverseDuration: const Duration(milliseconds: 310),
  );
  Timer? _idle;
  Offset _swipe = Offset.zero;
  bool _swiping = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _entrance.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) widget.onDismiss();
    });
    _entrance.forward();
    _restartIdle();
  }

  void _restartIdle() {
    if (_dismissed) return;
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 3), () {
      if (mounted) _entrance.reverse();
    });
  }

  void _swipeEnd({required bool horizontal}) {
    if (_dismissed) return;
    final travel = horizontal ? _swipe.dx.abs() : -_swipe.dy;
    if (travel < 72) {
      setState(() {
        _swiping = false;
        _swipe = Offset.zero;
      });
      _restartIdle();
      return;
    }
    _idle?.cancel();
    setState(() {
      _dismissed = true;
      _swiping = false;
      final size = MediaQuery.sizeOf(context);
      _swipe = horizontal
          ? Offset(_swipe.dx.sign * size.width, 0)
          : Offset(0, -size.height);
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) widget.onDismiss();
    });
  }

  void _swipeCancel() {
    if (_dismissed) return;
    setState(() {
      _swiping = false;
      _swipe = Offset.zero;
    });
    _restartIdle();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -.6),
        end: Offset.zero,
      ).animate(curve),
      child: ScaleTransition(
        scale: Tween<double>(begin: .84, end: 1).animate(curve),
        child: FadeTransition(
          opacity: _entrance,
          child: AnimatedContainer(
            duration: _swiping
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_swipe.dx, _swipe.dy, 0),
            child: Material(
              type: MaterialType.transparency,
              child: Listener(
                onPointerDown: (_) => _idle?.cancel(),
                onPointerUp: (_) => _restartIdle(),
                onPointerCancel: (_) => _restartIdle(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _restartIdle,
                  onHorizontalDragStart: (_) => setState(() => _swiping = true),
                  onHorizontalDragUpdate: (details) =>
                      setState(() => _swipe += Offset(details.delta.dx, 0)),
                  onHorizontalDragEnd: (_) => _swipeEnd(horizontal: true),
                  onHorizontalDragCancel: _swipeCancel,
                  onVerticalDragStart: (_) => setState(() => _swiping = true),
                  onVerticalDragUpdate: (details) => setState(() {
                    _swipe = Offset(
                      0,
                      (_swipe.dy + details.delta.dy).clamp(
                        double.negativeInfinity,
                        _maxDownwardPull,
                      ),
                    );
                  }),
                  onVerticalDragEnd: (_) => _swipeEnd(horizontal: false),
                  onVerticalDragCancel: _swipeCancel,
                  child: GlassElastic(
                    child: GlassFloatingSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
