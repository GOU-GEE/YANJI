import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import '../core/database/app_database.dart' show Task;
import 'shared.dart';
import 'exam_year_dialog.dart';
import '../application/task_input_parser.dart';
import '../design/yanji_theme.dart';

class TodayPage extends StatelessWidget {
  const TodayPage(this.app, {super.key});
  final StudyAppController app;
  @override
  Widget build(BuildContext context) {
    final completed = app.todayTasks.where(app.isTaskCompleted).length;
    return PageBody(
      title: '今天',
      showTitle: false,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  key: const Key('choose-exam-year'),
                  borderRadius: BorderRadius.circular(YanJiRadius.control),
                  onTap: app.busy ? null : () => chooseExamYear(context, app),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: YanJiLayout.touch,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1,
                      child: Text(
                        app.exam?.examName ?? '我的考研目标',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: YanJiSpacing.sm),
            Expanded(
              child: Text(
                '${app.examDateEstimated ? '预计' : ''}距离考试还有 ${app.daysUntilExam} 天',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: YanJiSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(vertical: YanJiSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(YanJiRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Metric('今天学习', durationLabel(app.todayDuration)),
                  ),
                  Expanded(
                    child: _Metric(
                      '今日任务',
                      '$completed / ${app.todayTasks.length}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: YanJiSpacing.sm),
        TextButton.icon(
          key: const Key('today-start'),
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            minimumSize: const Size(0, YanJiLayout.button),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          onPressed: app.busy ? null : () => chooseStudy(context, app),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(app.runningSession == null ? '开始学习' : '返回当前学习'),
        ),
        const SizedBox(height: YanJiSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                '今日任务',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => showTaskEditor(context, app),
              child: const Text('添加任务'),
            ),
          ],
        ),
        if (app.todayTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: YanJiSpacing.xl),
            child: Center(child: YanJiCaption('暂无任务')),
          ),
        ...app.todayTasks.map((t) => TaskTile(app, t)),
        if (app.todayDuration > 0) ...[
          const SizedBox(height: YanJiSpacing.lg),
          Text('科目时间', style: Theme.of(context).textTheme.titleLarge),
          ...app.subjects
              .where((s) => app.dayDuration(app.localNow, subjectId: s.id) > 0)
              .map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name),
                  trailing: Text(
                    durationLabel(
                      app.dayDuration(app.localNow, subjectId: s.id),
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      YanJiCaption(label, textAlign: TextAlign.center),
      const SizedBox(height: YanJiSpacing.xs),
      Text(
        value,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ],
  );
}

class TasksPage extends StatelessWidget {
  const TasksPage(this.app, {super.key});
  final StudyAppController app;
  @override
  Widget build(BuildContext context) => PageBody(
    title: '计划',
    showTitle: false,
    actions: [
      IconButton(
        tooltip: '管理科目',
        onPressed: () => context.push('/subjects'),
        icon: const Icon(Icons.subject),
      ),
    ],
    children: [
      YanJiAdaptiveRow(
        children: [
          Text('我的任务', style: Theme.of(context).textTheme.headlineSmall),
          FilledButton.icon(
            onPressed: () => showTaskEditor(context, app),
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ],
      ),
      const SizedBox(height: YanJiSpacing.md),
      if (app.tasks.isEmpty)
        const EmptyMessage('计划从一件小事开始', '添加任务，安排今天或未来的学习。'),
      ...app.tasks.map((t) => TaskTile(app, t, showDate: true)),
    ],
  );
}

class TaskTile extends StatelessWidget {
  const TaskTile(this.app, this.task, {super.key, this.showDate = false});
  final StudyAppController app;
  final Task task;
  final bool showDate;
  @override
  Widget build(BuildContext context) {
    final done = app.isTaskCompleted(task),
        cancelled = task.status == 'cancelled';
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: YanJiSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.push('/task/${task.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: YanJiSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        // Completed tasks recede visually while retaining a clear,
                        // centered strike through the glyphs.
                        color: done
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                        decoration: done || cancelled
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: done || cancelled
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                        decorationThickness: done || cancelled ? 1.5 : null,
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ),
                    const SizedBox(height: YanJiSpacing.xxs),
                    Text(
                      [
                        if (app.subject(task.subjectId) != null)
                          app.subject(task.subjectId)!.name,
                        if (task.repeatDaily == 1)
                          '每日'
                        else if (showDate)
                          task.scheduledDate ?? '未安排日期',
                        if (task.estimatedSeconds != null)
                          '已学 ${durationLabel(app.taskDuration(task.id))} / 预计 ${task.estimatedSeconds! ~/ 60} 分钟'
                        else if (app.taskDuration(task.id) > 0)
                          '已学 ${durationLabel(app.taskDuration(task.id))}',
                        if (done) '已完成',
                        if (cancelled) '已取消',
                        if (task.priority > 0)
                          task.priority == 1 ? '重要' : '优先完成',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: done
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!done && !cancelled)
            IconButton(
              tooltip: '学习 ${task.title}',
              onPressed: () => chooseStudy(context, app, taskId: task.id),
              icon: const Icon(Icons.play_circle_outline),
            ),
          Checkbox(
            semanticLabel: '完成任务：${task.title}',
            key: ValueKey('complete-${task.id}'),
            value: done,
            onChanged: app.busy || cancelled
                ? null
                : (v) => saveAction(
                    context,
                    () => app.setTaskStatus(task, v! ? 'completed' : 'todo'),
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> showTaskEditor(BuildContext context, StudyAppController app) =>
    showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) => TaskEditorPage(app, dialog: true),
      ),
    );

class TaskEditorPage extends StatefulWidget {
  const TaskEditorPage(this.app, {super.key, this.taskId, this.dialog = false});
  final StudyAppController app;
  final String? taskId;
  final bool dialog;
  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  late TextEditingController title, minutes;
  late String? subject, date;
  bool repeatDaily = false;
  bool subjectEdited = false, minutesEdited = false;
  TaskInputResult? recognition;
  void recognize(String input) {
    final result = TaskInputParser.parse(input, widget.app.subjects);
    setState(() {
      recognition = result;
      if (!subjectEdited) subject = result.subjectId;
      if (!minutesEdited) minutes.text = result.minutes?.toString() ?? '';
    });
  }

  Widget frame(List<Widget> children) => widget.dialog
      ? Dialog(
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          constraints: const BoxConstraints(maxWidth: YanJiLayout.form),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '添加任务',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: widget.app.busy
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        )
      : PageBody(title: '编辑任务', maxWidth: YanJiLayout.form, children: children);
  String? error;
  Task? get task => widget.app.task(widget.taskId);
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: task?.title);
    minutes = TextEditingController(
      text: task?.estimatedSeconds == null
          ? ''
          : '${task!.estimatedSeconds! ~/ 60}',
    );
    subject = task?.subjectId;
    date = task?.scheduledDate ?? widget.app.today;
    repeatDaily = task?.repeatDaily == 1;
    subjectEdited = minutesEdited = task != null;
  }

  @override
  void dispose() {
    title.dispose();
    minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => frame([
    TextField(
      key: const Key('task-title'),
      controller: title,
      onChanged: recognize,
      autofocus: true,
      decoration: const InputDecoration(
        labelText: '任务名称',
        hintText: '例如：学习英语一个小时',
      ),
    ),
    const SizedBox(height: YanJiSpacing.xs),
    YanJiCaption(recognition?.message ?? '输入科目和时长后自动识别，也可手动填写。'),
    const SizedBox(height: YanJiSpacing.lg),
    DropdownButtonFormField<String>(
      key: ValueKey('task-subject-$subject'),
      borderRadius: BorderRadius.circular(YanJiRadius.control),
      isExpanded: true,
      initialValue: subject,
      decoration: const InputDecoration(labelText: '科目（可选）'),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('暂不选择')),
        ...widget.app.activeSubjects.map(
          (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
        ),
        if (widget.app.subject(subject) case final current?)
          if (!widget.app.activeSubjects.any((s) => s.id == current.id))
            DropdownMenuItem(
              value: current.id,
              child: Text('${current.name}（已删除）'),
            ),
      ],
      onChanged: (v) => setState(() {
        subject = v;
        subjectEdited = true;
      }),
    ),
    const SizedBox(height: YanJiSpacing.lg),
    Row(
      children: [
        for (final daily in [false, true]) ...[
          if (daily) const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              key: ValueKey(daily ? 'task-daily' : 'task-once'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerLow,
                side: BorderSide(
                  color: repeatDaily == daily
                      ? Theme.of(context).colorScheme.outline
                      : Colors.transparent,
                ),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => setState(() {
                repeatDaily = daily;
                date = widget.app.today;
              }),
              child: Text(daily ? '每日' : '当日'),
            ),
          ),
        ],
      ],
    ),
    const SizedBox(height: YanJiSpacing.lg),
    TextField(
      key: const Key('task-minutes'),
      controller: minutes,
      onChanged: (_) => minutesEdited = true,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: '预计分钟（可选）'),
    ),
    const SizedBox(height: YanJiSpacing.lg),
    if (error != null) YanJiFieldError(error!),
    const SizedBox(height: YanJiSpacing.xl),
    FilledButton(
      key: const Key('save-task'),
      onPressed: widget.app.busy
          ? null
          : () async {
              final amount = minutes.text.trim().isEmpty
                  ? null
                  : int.tryParse(minutes.text);
              if ((title.text.trim().isEmpty &&
                      (subject == null || (amount ?? 0) <= 0)) ||
                  (minutes.text.trim().isNotEmpty &&
                      (amount == null || amount < 0))) {
                setState(() => error = '请填写名称，或选择科目和有效分钟数');
                return;
              }
              FocusScope.of(context).unfocus();
              if (await saveAction(
                    context,
                    () => widget.app.saveTask(
                      id: widget.taskId,
                      title: recognition?.title ?? title.text,
                      subjectId: subject,
                      date: date,
                      repeatDaily: repeatDaily,
                      estimatedSeconds: amount == null ? null : amount * 60,
                      priority: task?.priority ?? 0,
                      note: task?.note,
                    ),
                  ) &&
                  context.mounted) {
                context.pop();
              }
            },
      child: const Text('保存任务'),
    ),
    if (task != null) ...[
      const SizedBox(height: YanJiSpacing.sm),
      TextButton(
        onPressed: widget.app.busy
            ? null
            : () async {
                if (await saveAction(
                      context,
                      () => widget.app.setTaskStatus(
                        task!,
                        task!.status == 'cancelled' ? 'todo' : 'cancelled',
                      ),
                    ) &&
                    context.mounted) {
                  context.pop();
                }
              },
        child: Text(task!.status == 'cancelled' ? '恢复任务' : '取消任务'),
      ),
    ],
  ]);
}
