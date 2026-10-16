import 'package:flutter/material.dart';

import '../design/yanji_motion.dart';

import '../design/glass/glass_controls.dart';
import '../design/glass/glass_dropdown_form_field.dart';

import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import '../application/exam_schedule.dart';
import 'shared.dart';
import '../design/yanji_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage(this.app, {super.key});
  final StudyAppController app;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final name = TextEditingController(text: '2028 考研'),
      school = TextEditingController(),
      major = TextEditingController(),
      custom = TextEditingController(),
      score = TextEditingController();
  late int examYear;
  DateTime? date;
  @override
  void initState() {
    super.initState();
    examYear = ExamSchedule.nextYear(widget.app.localNow);
    name.text = '$examYear 考研';
    date = ExamSchedule.dateFor(examYear);
  }

  int step = 0;
  bool forward = true;
  String? error;
  final selected = <String>['政治', '英语一', '数学一', '408'];
  static const presets = [
    '政治',
    '英语一',
    '英语二',
    '数学一',
    '数学二',
    '数学三',
    '408',
    '专业课',
  ];
  @override
  void dispose() {
    for (final c in [name, school, major, custom, score]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    title: '研迹 YanJi',
    maxWidth: YanJiLayout.form,
    children: [
      MotionSwap(
        identity: step,
        child: YanJiCaption(
          '第 ${step + 1} 步，共 3 步 · ${['考试目标', '学习科目', '可选目标'][step]}',
        ),
      ),
      const SizedBox(height: YanJiSpacing.sm),
      TweenAnimationBuilder<double>(
        tween: Tween<double>(end: (step + 1) / 3),
        duration: YanJiMotion.durationOf(context),
        curve: YanJiMotion.curve,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          semanticsLabel: '设置进度，第 ${step + 1} 步，共 3 步',
        ),
      ),
      const SizedBox(height: YanJiSpacing.xl),
      MotionSwap(
        identity: step,
        direction: forward ? 1 : -1,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ['欢迎使用研迹', '你准备学习哪些科目？', '给努力一个方向'][step],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: YanJiSpacing.sm),
            YanJiCaption(
              [
                '从一个目标开始，把每天的学习留下来。',
                '选择常用科目，也可以自由添加。',
                '目标院校和分数可以以后再决定。',
              ][step],
            ),
            const SizedBox(height: YanJiSpacing.xl),
            if (step == 0) ...[
              GlassDropdownFormField<int>(
                key: const Key('onboarding-exam-year'),
                initialValue: examYear,
                isExpanded: true,
                borderRadius: BorderRadius.circular(YanJiRadius.control),
                decoration: const InputDecoration(labelText: '考研年份'),
                items: [
                  for (
                    var year = widget.app.localNow.year;
                    year <= widget.app.localNow.year + 10;
                    year++
                  )
                    DropdownMenuItem(value: year, child: Text('$year 考研')),
                ],
                onChanged: (value) => setState(() {
                  examYear = value!;
                  name.text = '$examYear 考研';
                  date = ExamSchedule.dateFor(examYear);
                }),
              ),
              const SizedBox(height: YanJiSpacing.sm),
              YanJiCaption('$examYear 考研对应 ${examYear - 1} 年底初试。'),
              if (ExamSchedule.isEstimate(examYear, date!))
                const YanJiCaption('当前为预计日期，以教育部公告为准；也可手动修改。'),
              const SizedBox(height: YanJiSpacing.md),
              GlassOutlinedButton.icon(
                key: const Key('exam-date'),
                onPressed: () async {
                  final now = widget.app.now();
                  final value = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime(now.year + 1, 12, 20),
                    firstDate: DateTime(now.year - 1, 1, 1),
                    lastDate: DateTime(now.year + 10, 12, 31),
                  );
                  if (value != null) setState(() => date = value);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(date == null ? '选择考试日期' : calendarDate(date!)),
              ),
            ],
            if (step == 1) ...[
              Wrap(
                spacing: YanJiSpacing.xs,
                runSpacing: YanJiSpacing.xs,
                children: presets
                    .map(
                      (s) => FilterChip(
                        label: Text(s),
                        selected: selected.contains(s),
                        onSelected: (v) => setState(() {
                          if (v) {
                            selected.add(s);
                          } else {
                            selected.remove(s);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: YanJiSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('custom-subject'),
                      controller: custom,
                      decoration: const InputDecoration(labelText: '自定义科目'),
                    ),
                  ),
                  IconButton(
                    tooltip: '添加科目',
                    onPressed: () {
                      final text = custom.text.trim();
                      if (text.isNotEmpty && !selected.contains(text)) {
                        setState(() => selected.add(text));
                        custom.clear();
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              ...selected
                  .where((s) => !presets.contains(s))
                  .map(
                    (s) => Chip(
                      label: Text(s),
                      onDeleted: () => setState(() => selected.remove(s)),
                    ),
                  ),
            ],
            if (step == 2) ...[
              TextField(
                controller: school,
                decoration: const InputDecoration(labelText: '目标学校（可跳过）'),
              ),
              const SizedBox(height: YanJiSpacing.md),
              TextField(
                controller: major,
                decoration: const InputDecoration(labelText: '目标专业（可跳过）'),
              ),
              const SizedBox(height: YanJiSpacing.md),
              TextField(
                controller: score,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '目标总分（可跳过）'),
              ),
              const SizedBox(height: YanJiSpacing.lg),
              YanJiPanel(
                muted: true,
                child: YanJiCaption('已选择 ${selected.length} 个科目 · 统计时区：中国标准时间'),
              ),
            ],
          ],
        ),
      ),
      MotionSection(
        child: error == null
            ? const SizedBox.shrink()
            : YanJiFieldError(error!),
      ),
      SizedBox(height: step == 0 ? YanJiSpacing.md : YanJiSpacing.xl),
      GlassFilledButton(
        key: const Key('onboarding-next'),
        onPressed: widget.app.busy
            ? null
            : () async {
                setState(() => error = null);
                if (step == 0 && (name.text.trim().isEmpty || date == null)) {
                  setState(() => error = '请填写考试名称并选择日期');
                  return;
                }
                if (step == 1 && selected.isEmpty) {
                  setState(() => error = '请至少选择一个科目');
                  return;
                }
                if (step < 2) {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    forward = true;
                    step++;
                  });
                  return;
                }
                final target = score.text.trim().isEmpty
                    ? null
                    : double.tryParse(score.text);
                if (score.text.trim().isNotEmpty &&
                    (target == null || !target.isFinite || target < 0)) {
                  setState(() => error = '请填写有效目标分');
                  return;
                }
                await saveAction(
                  context,
                  () => widget.app.onboard(
                    name: name.text,
                    date: calendarDate(date!),
                    school: school.text.trim().isEmpty
                        ? null
                        : school.text.trim(),
                    major: major.text.trim().isEmpty ? null : major.text.trim(),
                    totalScore: target == null ? null : (target * 100).round(),
                    subjectNames: selected,
                  ),
                );
              },
        child: MotionSwap(
          identity: (widget.app.busy, step),
          alignment: Alignment.center,
          child: Text(
            widget.app.busy
                ? '正在保存…'
                : step == 2
                ? '开启我的研迹'
                : '下一步',
          ),
        ),
      ),
      if (step == 0) ...[
        const SizedBox(height: YanJiSpacing.md),
        GlassOutlinedButton.icon(
          key: const Key('join-existing-device'),
          onPressed: widget.app.busy
              ? null
              : () => context.push('/device-tree'),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('从已有设备导入'),
        ),
      ],
      if (step > 0) ...[
        const SizedBox(height: YanJiSpacing.md),
        GlassTextButton(
          onPressed: widget.app.busy
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    forward = false;
                    step--;
                  });
                },
          child: const Text('上一步'),
        ),
      ],
    ],
  );
}
