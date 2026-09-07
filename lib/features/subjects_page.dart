import 'package:flutter/material.dart';

import '../application/study_app_controller.dart';
import '../core/database/app_database.dart' show Subject;
import 'shared.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage(this.app, {super.key});
  final StudyAppController app;
  Future<void> edit(
    BuildContext context, {
    Subject? subject,
    String? parentId,
  }) async {
    final name = TextEditingController(text: subject?.name);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            subject == null ? (parentId == null ? '新增一级科目' : '新增二级科目') : '编辑科目',
          ),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('subject-name'),
                controller: name,
                decoration: const InputDecoration(labelText: '科目名称'),
              ),
              if (error != null) Text(error!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('save-subject'),
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  setState(() => error = '请填写科目名称');
                  return;
                }
                if (await saveAction(
                      context,
                      () => app.saveSubject(
                        id: subject?.id,
                        parentId: parentId,
                        name: name.text,
                        score: subject?.targetScoreX100,
                      ),
                    ) &&
                    context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    // Dialog removal animates; dispose text controllers after its frame finishes.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
  }

  Widget actions(BuildContext context, Subject subject) =>
      PopupMenuButton<String>(
        tooltip: '科目操作：${subject.name}',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (action) {
          if (action == 'edit') {
            edit(context, subject: subject);
          } else if (action == 'up') {
            saveAction(context, () => app.moveSubject(subject, -1));
          } else if (action == 'down') {
            saveAction(context, () => app.moveSubject(subject, 1));
          } else {
            saveAction(context, () => app.deleteSubject(subject));
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('修改名称')),
          const PopupMenuItem(value: 'up', child: Text('上移')),
          const PopupMenuItem(value: 'down', child: Text('下移')),
          PopupMenuItem(value: 'archive', child: const Text('删除')),
        ],
      );
  Future<void> confirmPermanentDelete(
    BuildContext context,
    Subject subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('彻底删除科目？'),
        content: Text('「${subject.name}」及其二级科目将无法恢复，关联任务和学习记录也将从应用中移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await saveAction(context, () => app.permanentlyDeleteSubject(subject));
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    title: '我的科目',
    actions: [
      IconButton(
        tooltip: '新增科目',
        onPressed: () => edit(context),
        icon: const Icon(Icons.add),
      ),
    ],
    children: [
      if (app.subjects.isEmpty) const EmptyMessage('还没有科目', '点击右上角添加一级科目。'),
      ...app.subjects
          .where((s) => s.parentSubjectId == null && app.isSubjectVisible(s))
          .map(
            (parent) => ExpansionTile(
              key: PageStorageKey('subject-${parent.id}'),
              tilePadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Expanded(child: Text(parent.name)),
                  actions(context, parent),
                ],
              ),
              childrenPadding: const EdgeInsets.only(left: 16),
              children: [
                ...app.subjects
                    .where(
                      (s) => s.parentSubjectId == parent.id && s.archived == 0,
                    )
                    .map(
                      (child) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(child.name),
                        onTap: () => edit(context, subject: child),
                        trailing: actions(context, child),
                      ),
                    ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: ValueKey('add-child-${parent.id}'),
                    onPressed: parent.archived == 1
                        ? null
                        : () => edit(context, parentId: parent.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加二级科目'),
                  ),
                ),
              ],
            ),
          ),
      const SizedBox(height: 24),
      const YanJiCaption(
        '为了更准确地识别任务输入中的科目，建议添加细分科目，例如数学一下的高等数学、线性代数，408 下的数据结构、计算机组成原理。学习时间统一计入所属一级科目。',
      ),
      const SizedBox(height: 16),
      ExpansionTile(
        key: const PageStorageKey('deleted-subjects'),
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        title: const Text('已删除的科目'),
        children: [
          if (!app.subjects.any((s) => s.archived == 1))
            const Padding(
              padding: EdgeInsets.all(16),
              child: YanJiCaption('暂无已删除的科目'),
            ),
          ...app.subjects
              .where((s) => s.archived == 1)
              .map(
                (subject) => ListTile(
                  title: Text(subject.name),
                  subtitle: subject.parentSubjectId == null
                      ? null
                      : Text(app.subject(subject.parentSubjectId)?.name ?? ''),
                  trailing: PopupMenuButton<String>(
                    tooltip: '已删除科目操作：${subject.name}',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'restore') {
                        saveAction(context, () => app.restoreSubject(subject));
                      } else {
                        confirmPermanentDelete(context, subject);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('彻底删除')),
                      PopupMenuItem(value: 'restore', child: Text('恢复')),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ],
  );
}
