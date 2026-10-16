import 'package:flutter/material.dart';

import '../design/glass/glass_controls.dart';
import '../design/glass/glass_notice.dart';
import '../design/yanji_theme.dart';
import '../sync/files/automatic_sync_controller.dart';

/// Owned by the app so an in-flight manual sync survives switching pages.
class ProfileSyncController extends ChangeNotifier {
  AutomaticSyncController? _sync;
  String? _state, _result;
  bool waiting = false, _disposed = false;

  void bind(AutomaticSyncController? sync) {
    if (identical(_sync, sync)) return;
    _sync?.removeListener(_changed);
    _sync = sync;
    _sync?.addListener(_changed);
    _changed();
  }

  void _changed() {
    final state = '${_sync?.message}|${_sync?.error}';
    if (_state != state) {
      _state = state;
      if (!waiting) {
        _result = null;
      }
    }
    notifyListeners();
  }

  String message(bool hasPeers) {
    if (waiting) return '正在同步设备记录，请保持双端应用打开并等待完成。';
    if (_result != null) return _result!;
    if (!hasPeers) return '本机记录已保存，配对设备后可自动同步';
    final summary = _sync?.message ?? '本机记录已保存，仍有记录待同步';
    if (_sync?.complete == true) return summary;
    return '$summary。请保持另一台设备的研迹打开，点击同步并等待完成。';
  }

  Future<void> run(Future<void> Function() sync) async {
    if (waiting || _disposed) return;
    waiting = true;
    _result = null;
    notifyListeners();
    try {
      await sync();
      _result = '已同步到全部已配对设备';
    } catch (error) {
      _result = GlassNotice.chineseMessage(error.toString());
    } finally {
      waiting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sync?.removeListener(_changed);
    super.dispose();
  }
}

class ProfileSyncStatus extends StatefulWidget {
  const ProfileSyncStatus({
    super.key,
    required this.controller,
    required this.hasPeers,
    required this.busy,
    required this.onSync,
  });

  final ProfileSyncController controller;
  final bool hasPeers, busy;
  final Future<void> Function() onSync;

  @override
  State<ProfileSyncStatus> createState() => _ProfileSyncStatusState();
}

class _ProfileSyncStatusState extends State<ProfileSyncStatus> {
  bool expanded = false;
  String? previousMessage;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final message = controller.message(widget.hasPeers);
      if (previousMessage != message) {
        previousMessage = message;
        expanded = false;
      }
      final style = Theme.of(context).textTheme.bodyMedium!;
      final actionStyle = TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
      return YanjiGlassControl(
        key: const Key('profile-sync-status'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: YanJiSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final painter = TextPainter(
                      text: TextSpan(text: message, style: style),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                      locale: Localizations.maybeLocaleOf(context),
                      maxLines: 1,
                    )..layout(maxWidth: constraints.maxWidth);
                    final overflows = painter.didExceedMaxLines;
                    painter.dispose();
                    final isExpanded = expanded && overflows;
                    return Semantics(
                      button: overflows,
                      expanded: overflows ? isExpanded : null,
                      child: InkWell(
                        key: const Key('profile-sync-message'),
                        borderRadius: BorderRadius.circular(12),
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                        onTap: overflows
                            ? () => setState(() => expanded = !isExpanded)
                            : null,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 40),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: YanJiSpacing.sm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    message,
                                    style: style,
                                    maxLines: isExpanded ? null : 1,
                                    overflow: isExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                  ),
                                ),
                                if (overflows)
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    key: const Key('profile-sync-expand'),
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
              const SizedBox(width: YanJiSpacing.sm),
              TextButton(
                key: const Key('profile-sync'),
                style: actionStyle,
                onPressed: widget.busy || controller.waiting
                    ? null
                    : () => controller.run(widget.onSync),
                child: controller.waiting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: '同步中',
                        ),
                      )
                    : const Text('同步'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
