import 'dart:async';

import 'package:flutter/material.dart';

import '../design/yanji_motion.dart';

import '../design/glass/glass_controls.dart';

import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import 'shared.dart';
import '../design/yanji_theme.dart';

class TimerPage extends StatefulWidget {
  const TimerPage(this.app, {super.key});
  final StudyAppController app;
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  Timer? ticker;
  int? completedDuration;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
    if (state == AppLifecycleState.detached) {
      unawaited(widget.app.finishStudyForProcessExit());
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MotionSwap(
    identity: widget.app.runningSession == null,
    fill: true,
    alignment: Alignment.topCenter,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final app = widget.app, s = app.runningSession;
    if (s == null) {
      final elapsed = completedDuration ?? app.lastCompletedStudyDuration;
      return Scaffold(
        appBar: GlassAppBar(title: const Text('学习计时')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(YanJiSpacing.lg),
              child: EmptyMessage(
                '这段学习已完成',
                '此次时间${elapsed == null ? '' : ' ${durationLabel(elapsed)}'}',
                action: GlassFilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('回到今天'),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return PageBody(
      title: '专注学习',
      maxWidth: YanJiLayout.form,
      children: [
        const SizedBox(height: YanJiSpacing.xxl),
        if (app.task(s.taskId) case final linked?) ...[
          Center(
            child: YanJiCaption(
              '任务已学 ${durationLabel(app.taskDuration(linked.id))}${linked.estimatedSeconds == null ? '' : ' / ${linked.estimatedSeconds! ~/ 60} 分钟'}${app.isTaskCompleted(linked) ? ' · 已自动完成' : ''}',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: YanJiSpacing.md),
        ],
        Center(
          child: Text(
            app.subject(s.subjectId)?.name ?? '学习',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: YanJiSpacing.sm),
        if (app.task(s.taskId) != null)
          Center(
            child: Text(app.task(s.taskId)!.title, textAlign: TextAlign.center),
          ),
        const SizedBox(height: YanJiSpacing.xxl),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              clockLabel(app.sessionDuration(s.id)),
              key: const Key('timer-value'),
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
        ),
        const SizedBox(height: YanJiSpacing.md),
        Center(
          child: Semantics(
            liveRegion: true,
            child: MotionSwap(
              identity: s.status,
              alignment: Alignment.center,
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: YanJiSpacing.xs,
                children: [
                  Icon(
                    s.status == 'paused'
                        ? Icons.pause_circle_outline
                        : Icons.timelapse_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    s.status == 'paused' ? '已暂停 · 休息一下' : '正在学习',
                    key: const Key('timer-state'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: YanJiSpacing.xl),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassFilledButton.icon(
                  key: const Key('pause-resume'),
                  onPressed: app.busy
                      ? null
                      : () => saveAction(
                          context,
                          s.status == 'paused'
                              ? app.resumeStudy
                              : app.pauseStudy,
                        ),
                  icon: MotionSwap(
                    identity: s.status,
                    child: Icon(
                      s.status == 'paused' ? Icons.play_arrow : Icons.pause,
                    ),
                  ),
                  label: MotionSwap(
                    identity: s.status,
                    child: Text(s.status == 'paused' ? '继续学习' : '暂停'),
                  ),
                ),
                const SizedBox(height: YanJiSpacing.md),
                GlassOutlinedButton(
                  key: const Key('stop-study'),
                  onPressed: app.busy
                      ? null
                      : () async {
                          final elapsed = app.sessionDuration(s.id);
                          if (!await saveAction(context, app.stopStudy) ||
                              !context.mounted) {
                            return;
                          }
                          setState(() => completedDuration = elapsed);
                          final task = app.task(s.taskId);
                          if (task != null && app.isTaskCompleted(task)) {
                            await saveAction(
                              context,
                              () => app.setTaskStatus(task, 'completed'),
                            );
                          }
                        },
                  child: const Text('结束学习'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage(this.app, {super.key});
  final StudyAppController app;
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late String date;
  late TextEditingController content;
  bool saved = false;
  @override
  void initState() {
    super.initState();
    date = widget.app.today;
    content = TextEditingController(text: widget.app.review(date)?.content);
  }

  @override
  void dispose() {
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    title: '每日复盘',
    children: [
      GlassOutlinedButton.icon(
        onPressed: () async {
          final chosen = await showDatePicker(
            context: context,
            initialDate: DateTime.parse(date),
            firstDate: DateTime(2020),
            lastDate: DateTime(2040),
          );
          if (chosen != null) {
            setState(() {
              date = calendarDate(chosen);
              content.text = widget.app.review(date)?.content ?? '';
              saved = false;
            });
          }
        },
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(date),
      ),
      const SizedBox(height: 20),
      const Text('今天完成了什么？遇到了什么问题？\n明天准备怎么调整？'),
      const SizedBox(height: 20),
      TextField(
        key: const Key('review-content'),
        controller: content,
        minLines: 10,
        maxLines: 20,
        onChanged: (_) => setState(() => saved = false),
        decoration: const InputDecoration(
          hintText: '写下今天的收获，也留一点空间给明天。',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 24),
      GlassFilledButton(
        key: const Key('save-review'),
        onPressed: widget.app.busy
            ? null
            : () async {
                if (await saveAction(
                      context,
                      () => widget.app.saveReview(date, content.text),
                    ) &&
                    mounted) {
                  setState(() => saved = true);
                }
              },
        child: Text(saved ? '已保存' : '保存复盘'),
      ),
      GlassTextButton(
        onPressed: widget.app.busy
            ? null
            : () async {
                final clear = await showDialog<bool>(
                  context: context,
                  builder: (context) => GlassAlertDialog(
                    title: const Text('清空这天的复盘？'),
                    content: const Text('清空后仍可重新填写。'),
                    actions: [
                      GlassTextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('保留'),
                      ),
                      GlassTextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
                if (clear == true &&
                    context.mounted &&
                    await saveAction(
                      context,
                      () => widget.app.saveReview(date, ''),
                    ) &&
                    mounted) {
                  setState(() {
                    content.clear();
                    saved = true;
                  });
                }
              },
        child: const Text('清空复盘'),
      ),
    ],
  );
}
