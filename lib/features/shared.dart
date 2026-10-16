import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/glass/glass_controls.dart';
import '../design/glass/glass_dropdown_form_field.dart';
import '../design/glass/glass_notice.dart';

import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import '../sync/trust/trust_chain.dart';
import '../design/yanji_theme.dart';
import '../design/glass/yanji_glass_theme.dart';

/// Root pages share a bucket so changing navigation tabs preserves reading position.
class RootPageScrollMemory extends InheritedWidget {
  const RootPageScrollMemory({
    super.key,
    required this.bucket,
    required super.child,
  });
  final PageStorageBucket bucket;
  static PageStorageBucket? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RootPageScrollMemory>()
      ?.bucket;
  @override
  bool updateShouldNotify(RootPageScrollMemory oldWidget) =>
      bucket != oldWidget.bucket;
}

class _PageScrollStorage extends StatelessWidget {
  const _PageScrollStorage({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final bucket = RootPageScrollMemory.maybeOf(context);
    return bucket == null ? child : PageStorage(bucket: bucket, child: child);
  }
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.showTitle = true,
    this.maxWidth = YanJiLayout.content,
    this.footer = const [],
  });
  final String title;
  final bool showTitle;
  final double maxWidth;
  final List<Widget> children, actions, footer;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      extendBodyBehindAppBar: showTitle || actions.isNotEmpty,
      appBar: showTitle || actions.isNotEmpty
          ? GlassAppBar(title: showTitle ? Text(title) : null, actions: actions)
          : null,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sideSpace = math.max(
              0.0,
              (constraints.maxWidth - maxWidth) / 2,
            );
            return _PageScrollStorage(
              child: CustomScrollView(
                key: PageStorageKey(title),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      (media.size.width < YanJiLayout.railBreakpoint
                              ? YanJiSpacing.md
                              : YanJiSpacing.lg) +
                          YanjiDockClearance.of(context).left +
                          sideSpace,
                      YanJiSpacing.sm +
                          media.padding.top +
                          (showTitle || actions.isNotEmpty
                              ? kToolbarHeight
                              : 0),
                      (media.size.width < YanJiLayout.railBreakpoint
                              ? YanJiSpacing.md
                              : YanJiSpacing.lg) +
                          sideSpace,
                      math.max(
                        YanJiSpacing.xl + media.padding.bottom,
                        YanjiDockClearance.of(context).bottom,
                      ),
                    ),
                    sliver: footer.isEmpty
                        ? SliverList.list(children: children)
                        : SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...children,
                                const Spacer(),
                                ...footer,
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A pending transfer closes only when its operation completes or fails.
Future<T> withBlockingProgress<T>(
  BuildContext context,
  String message,
  Future<T> Function() action,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: GlassAlertDialog(
        dismissibleByDrag: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: YanJiSpacing.lg),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: YanJiSpacing.sm),
            const Text('请保持两台设备的研迹打开。'),
          ],
        ),
      ),
    ),
  );
  unawaited(navigator.push(route));
  try {
    return await action();
  } finally {
    if (route.isActive) navigator.removeRoute(route);
  }
}

Future<bool> revokePairedDevice(
  BuildContext context,
  StudyAppController app,
  TrustedPeer peer,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => GlassAlertDialog(
      title: Text('删除“${peer.deviceName}”？'),
      content: const Text('删除将永久撤销该设备的同步授权，该设备之后产生的记录将不再被信任。'),
      actions: [
        GlassTextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        GlassFilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await app.revokeTrustedPeer(peer);
    return true;
  } catch (error) {
    if (context.mounted) GlassNotice.show(context, error.toString());
    return false;
  }
}

Future<void> editPairedDevice(
  BuildContext context,
  StudyAppController app,
  TrustedPeer peer,
) => showDialog<void>(
  context: context,
  builder: (_) => _DeviceEditDialog(app: app, peer: peer),
);

class _DeviceEditDialog extends StatefulWidget {
  const _DeviceEditDialog({required this.app, required this.peer});
  final StudyAppController app;
  final TrustedPeer peer;
  @override
  State<_DeviceEditDialog> createState() => _DeviceEditDialogState();
}

class _DeviceEditDialogState extends State<_DeviceEditDialog> {
  late final input = TextEditingController(text: widget.peer.deviceName);
  bool saving = false;
  String? error;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = input.text.trim();
    if (name.isEmpty || name.length > 40) {
      setState(() => error = '设备名称请输入一到四十个字');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (name != widget.peer.deviceName) {
        await widget.app.renameTrustedPeer(widget.peer, name);
      }
      if (mounted) Navigator.pop(context);
    } catch (caught) {
      if (mounted) {
        setState(() => error = GlassNotice.chineseMessage(caught.toString()));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => saving = true);
    final deleted = await revokePairedDevice(context, widget.app, widget.peer);
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context);
    } else {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade300;
    return PopScope(
      canPop: !saving,
      child: GlassAlertDialog(
        dismissibleByDrag: !saving,
        title: Row(
          children: [
            const Expanded(child: Text('编辑设备')),
            IconButton(
              key: const Key('close-device-edit'),
              tooltip: '关闭',
              onPressed: saving ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: TextField(
          key: const Key('device-name-input'),
          controller: input,
          autofocus: true,
          enabled: !saving,
          maxLength: 40,
          decoration: InputDecoration(labelText: '设备名称', errorText: error),
          onSubmitted: saving ? null : (_) => _save(),
        ),
        actionBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: red),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GlassTextButton(
                key: const Key('delete-device'),
                style: TextButton.styleFrom(
                  foregroundColor: red,
                  textStyle: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontSize: 13),
                ),
                onPressed: saving ? null : _delete,
                child: const Text('删除'),
              ),
            ),
            const SizedBox(width: YanJiSpacing.sm),
            GlassFilledButton(
              key: const Key('complete-device-edit'),
              onPressed: saving ? null : _save,
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(this.title, this.detail, {super.key, this.action});
  final String title, detail;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: YanJiSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: YanJiSpacing.xs),
        YanJiCaption(detail, textAlign: TextAlign.center),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(top: YanJiSpacing.md),
            child: action,
          ),
      ],
    ),
  );
}

Future<bool> saveAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (_) {
    if (context.mounted) {
      GlassNotice.show(context, '未能保存，数据没有丢弃。请重试。');
    }
    return false;
  }
}

Future<void> chooseStudy(
  BuildContext context,
  StudyAppController app, {
  String? taskId,
}) async {
  if (app.runningSession != null) {
    await context.push('/timer');
    return;
  }
  if (app.activeSubjects.isEmpty) {
    await context.push('/subjects');
    return;
  }
  final task = app.task(taskId);
  final availableSubjects = app.studySubjects;
  final availableTasks = app.tasks
      .where((t) => !app.isTaskCompleted(t) && t.status != 'cancelled')
      .toList();
  String selected = availableSubjects.any((s) => s.id == task?.subjectId)
      ? task!.subjectId!
      : availableSubjects.first.id;
  String? selectedTask = taskId;
  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) => GlassDialog(
        alignment: Alignment.center,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: YanJiSpacing.md,
          vertical: YanJiSpacing.lg,
        ),
        constraints: const BoxConstraints(maxWidth: YanJiLayout.form),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(YanJiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '开始一段专注学习',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: YanJiSpacing.lg),
              GlassDropdownFormField<String>(
                borderRadius: BorderRadius.circular(YanJiRadius.control),
                isExpanded: true,
                key: const Key('study-subject'),
                initialValue: selected,
                decoration: const InputDecoration(labelText: '学习科目'),
                items: availableSubjects
                    .map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  selected = v!;
                  selectedTask = null;
                }),
              ),
              const SizedBox(height: YanJiSpacing.md),
              GlassDropdownFormField<String>(
                borderRadius: BorderRadius.circular(YanJiRadius.control),
                isExpanded: true,
                key: ValueKey('study-task-$selected'),
                initialValue: selectedTask,
                decoration: const InputDecoration(labelText: '关联任务（可选）'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('不关联任务'),
                  ),
                  ...availableTasks
                      .where(
                        (t) =>
                            !app.isTaskCompleted(t) &&
                            t.status != 'cancelled' &&
                            (t.subjectId == null || t.subjectId == selected),
                      )
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.title, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                ],
                onChanged: (v) => setState(() => selectedTask = v),
              ),
              const SizedBox(height: YanJiSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: GlassOutlinedButton(
                      key: const Key('cancel-study'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      onPressed: app.busy ? null : () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassFilledButton.icon(
                      key: const Key('confirm-start'),
                      onPressed: app.busy
                          ? null
                          : () async {
                              if (await saveAction(
                                    context,
                                    () => app.startStudy(
                                      selected,
                                      taskId: selectedTask,
                                    ),
                                  ) &&
                                  context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('开始计时'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (context.mounted && app.runningSession != null) {
    await context.push('/timer');
  }
}

class YanJiPanel extends StatelessWidget {
  const YanJiPanel({super.key, required this.child, this.muted = false});
  final Widget child;
  final bool muted;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(YanJiSpacing.md),
      decoration: BoxDecoration(
        color: muted ? colors.surfaceContainerLow : colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(YanJiRadius.card),
      ),
      child: child,
    );
  }
}

class YanJiCaption extends StatelessWidget {
  const YanJiCaption(this.text, {super.key, this.textAlign});
  final String text;
  final TextAlign? textAlign;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class YanJiFieldError extends StatelessWidget {
  const YanJiFieldError(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: YanJiSpacing.md),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}

/// Related items become vertical when readable labels no longer fit a row.
class YanJiAdaptiveRow extends StatelessWidget {
  const YanJiAdaptiveRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => YanJiLayout.stacked(context)
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: YanJiSpacing.sm),
              children[i],
            ],
          ],
        )
      : Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: YanJiSpacing.md),
              Expanded(child: children[i]),
            ],
          ],
        );
}
