import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_controls.dart';
import 'liquid_glass_surface.dart';
import 'yanji_glass_theme.dart';

/// An anchored glass selection menu with the same value API as the form fields
/// used in onboarding, task editing and study dialogs.
class GlassDropdownFormField<T> extends StatefulWidget {
  const GlassDropdownFormField({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.decoration = const InputDecoration(),
    this.isExpanded = true,
    this.borderRadius,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? initialValue;
  final InputDecoration decoration;
  final bool isExpanded;
  final BorderRadius? borderRadius;

  @override
  State<GlassDropdownFormField<T>> createState() =>
      _GlassDropdownFormFieldState<T>();
}

class _GlassDropdownFormFieldState<T> extends State<GlassDropdownFormField<T>> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _menu;
  late T? _value = widget.initialValue;

  @override
  void didUpdateWidget(GlassDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  void _close() {
    _menu?.remove();
    _menu?.dispose();
    _menu = null;
    if (mounted) setState(() {});
  }

  void _select(T? value) {
    _close();
    setState(() => _value = value);
    widget.onChanged?.call(value);
  }

  void _open() {
    if (widget.onChanged == null || widget.items.isEmpty) return;
    if (_menu != null) {
      _close();
      return;
    }
    final box = context.findRenderObject()! as RenderBox;
    final global = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final height = math.min(320.0, widget.items.length * 48.0 + 16);
    final below = screen.height - global.dy - box.size.height - safe.bottom;
    final above = global.dy - safe.top;
    final popAbove = below < height + 4 && above > below;
    final available = popAbove ? above : below;
    final menuHeight = math.min(height, math.max(96.0, available - 12));
    final offsetY = popAbove ? -menuHeight - 4 : box.size.height + 4;
    _menu = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('glass-dropdown-dismiss'),
              behavior: HitTestBehavior.opaque,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, offsetY),
            child: SizedBox(
              width: box.size.width,
              height: menuHeight,
              child: YanjiGlassSurface(
                radius: widget.borderRadius?.topLeft.x ?? 18,
                strength: YanjiGlassStrength.modal,
                child: Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return SizedBox(
                        height: 48,
                        child: Material(
                          color: item.value == _value
                              ? Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: .35)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: item.enabled
                                ? () => _select(item.value)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DefaultTextStyle(
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!,
                                      child: item.child,
                                    ),
                                  ),
                                  if (item.value == _value)
                                    Icon(
                                      Icons.check,
                                      size: 17,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_menu!);
    setState(() {});
  }

  @override
  void dispose() {
    _menu?.remove();
    _menu?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.items
        .where((item) => item.value == _value)
        .firstOrNull;
    final decoration = widget.decoration.copyWith(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
    return CompositedTransformTarget(
      link: _link,
      child: YanjiGlassControl(
        elastic: widget.onChanged != null,
        radius: widget.borderRadius?.topLeft.x ?? 16,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onChanged == null ? null : _open,
            borderRadius: widget.borderRadius,
            child: InputDecorator(
              decoration: decoration,
              isFocused: _menu != null,
              isEmpty: selected == null,
              child: Row(
                children: [
                  Expanded(child: selected?.child ?? const SizedBox.shrink()),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
