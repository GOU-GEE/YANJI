import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import '../design/yanji_theme.dart';

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
  Widget build(BuildContext context) => Scaffold(
    appBar: showTitle || actions.isNotEmpty
        ? AppBar(title: showTitle ? Text(title) : null, actions: actions)
        : null,
    body: SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: CustomScrollView(
            key: PageStorageKey(title),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.sizeOf(context).width < YanJiLayout.railBreakpoint
                      ? YanJiSpacing.md
                      : YanJiSpacing.lg,
                  YanJiSpacing.sm +
                      (!showTitle && actions.isEmpty
                          ? MediaQuery.paddingOf(context).top
                          : 0),
                  MediaQuery.sizeOf(context).width < YanJiLayout.railBreakpoint
                      ? YanJiSpacing.md
                      : YanJiSpacing.lg,
                  YanJiSpacing.xl + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: footer.isEmpty
                    ? SliverList.list(children: children)
                    : SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [...children, const Spacer(), ...footer],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('未能保存，数据没有丢弃。请重试。')));
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
      builder: (context, setState) => Dialog(
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
              DropdownButtonFormField<String>(
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
              DropdownButtonFormField<String>(
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
                    child: OutlinedButton(
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
                    child: FilledButton.icon(
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
