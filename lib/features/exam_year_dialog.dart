import 'package:flutter/material.dart';

import '../application/exam_schedule.dart';
import '../application/study_app_controller.dart';
import '../design/yanji_theme.dart';
import 'shared.dart';

Future<void> chooseExamYear(
  BuildContext context,
  StudyAppController app,
) async {
  var year = app.examYear;
  var date =
      DateTime.tryParse(app.exam?.examDate ?? '') ?? ExamSchedule.dateFor(year);
  var saving = false;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('选择考研年份'),
        scrollable: true,
        content: SizedBox(
          width: YanJiLayout.form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                key: const Key('exam-year'),
                initialValue: year,
                isExpanded: true,
                borderRadius: BorderRadius.circular(YanJiRadius.control),
                decoration: const InputDecoration(labelText: '考研年份'),
                items: [
                  for (var value = 2024; value <= 2100; value++)
                    DropdownMenuItem(value: value, child: Text('$value 考研')),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(() {
                        year = value!;
                        date = ExamSchedule.dateFor(year);
                      }),
              ),
              const SizedBox(height: YanJiSpacing.md),
              YanJiCaption('$year 考研对应 ${year - 1} 年底初试。'),
              const SizedBox(height: YanJiSpacing.sm),
              Text(
                '${ExamSchedule.isEstimate(year, date) ? '预计初试' : '初试日期'}：${calendarDate(date)}',
              ),
              if (ExamSchedule.isEstimate(year, date)) ...[
                const SizedBox(height: YanJiSpacing.xs),
                const YanJiCaption('具体日期以教育部公告为准，公布后可在此修改。'),
              ],
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2100, 12, 31),
                        );
                        if (picked != null && context.mounted) {
                          setState(() => date = picked);
                        }
                      },
                child: const Text('修改考试日期'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('save-exam-year'),
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    final saved = await saveAction(
                      context,
                      () => app.setExamYear(year, date: date),
                    );
                    if (!context.mounted) return;
                    if (saved) {
                      Navigator.pop(context);
                    } else {
                      setState(() => saving = false);
                    }
                  },
            child: Text(saving ? '保存中…' : '确定'),
          ),
        ],
      ),
    ),
  );
}
