import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import '../design/glass/glass_controls.dart';
import '../design/yanji_theme.dart';
import 'shared.dart';

String formatTargetScoreX100(int scoreX100) {
  final whole = scoreX100 ~/ 100;
  final fraction = scoreX100 % 100;
  if (fraction == 0) return '$whole';
  final decimals = fraction % 10 == 0
      ? '${fraction ~/ 10}'
      : fraction.toString().padLeft(2, '0');
  return '$whole.$decimals';
}

class TargetGoalPage extends StatefulWidget {
  const TargetGoalPage(this.app, {super.key});
  final StudyAppController app;

  @override
  State<TargetGoalPage> createState() => _TargetGoalPageState();
}

class _TargetGoalPageState extends State<TargetGoalPage> {
  late final TextEditingController school;
  late final TextEditingController major;
  late final TextEditingController score;
  String? error;

  @override
  void initState() {
    super.initState();
    final exam = widget.app.exam;
    school = TextEditingController(text: exam?.targetSchool ?? '');
    major = TextEditingController(text: exam?.targetMajor ?? '');
    final existingScore = exam?.targetTotalScoreX100;
    score = TextEditingController(
      text: existingScore == null ? '' : formatTargetScoreX100(existingScore),
    );
  }

  @override
  void dispose() {
    school.dispose();
    major.dispose();
    score.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    title: '我的目标',
    children: [
      const YanJiCaption('记录想去的学校、专业和目标总分，之后也可以随时修改。留空的项目不会显示在“我的”页。'),
      const SizedBox(height: YanJiSpacing.lg),
      TextField(
        key: const Key('target-school'),
        controller: school,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(labelText: '目标学校'),
      ),
      const SizedBox(height: YanJiSpacing.md),
      TextField(
        key: const Key('target-major'),
        controller: major,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(labelText: '目标专业'),
      ),
      const SizedBox(height: YanJiSpacing.md),
      TextField(
        key: const Key('target-total-score'),
        controller: score,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: '目标总分'),
      ),
      if (error != null) ...[
        const SizedBox(height: YanJiSpacing.sm),
        YanJiFieldError(error!),
      ],
      const SizedBox(height: YanJiSpacing.xl),
      GlassFilledButton(
        key: const Key('save-target-goal'),
        onPressed: widget.app.busy ? null : save,
        child: Text(widget.app.busy ? '正在保存…' : '保存'),
      ),
    ],
  );

  Future<void> save() async {
    setState(() => error = null);
    final scoreText = score.text.trim();
    final parsedScore = scoreText.isEmpty ? null : double.tryParse(scoreText);
    if (scoreText.isNotEmpty &&
        (parsedScore == null || !parsedScore.isFinite || parsedScore < 0)) {
      setState(() => error = '请填写有效目标分');
      return;
    }
    final saved = await saveAction(
      context,
      () => widget.app.saveExamGoal(
        school: school.text,
        major: major.text,
        totalScoreX100: parsedScore == null
            ? null
            : (parsedScore * 100).round(),
      ),
    );
    if (!mounted) return;
    if (saved) context.pop();
  }
}
