import 'package:flutter/material.dart';

import '../design/yanji_motion.dart';

import '../design/glass/glass_controls.dart';

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
        builder: (context, setState) => GlassAlertDialog(
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
            GlassTextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            GlassFilledButton(
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

  Widget actions(BuildContext context, Subject subject) => Builder(
    builder: (buttonContext) => IconButton(
      tooltip: '科目操作：${subject.name}',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: const Icon(Icons.more_horiz),
      onPressed: () => showSubjectActions(buttonContext, subject),
    ),
  );

  Future<void> showSubjectActions(BuildContext context, Subject subject) async {
    final overlay =
        Navigator.of(
              context,
              rootNavigator: true,
            ).overlay!.context.findRenderObject()!
            as RenderBox;
    final button = context.findRenderObject()! as RenderBox;
    final anchor = button.localToGlobal(Offset.zero, ancestor: overlay);
    final media = MediaQuery.of(context);
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final labelPainter = TextPainter(
      text: TextSpan(text: '修改名称', style: labelStyle),
      textDirection: Directionality.of(context),
      textScaler: media.textScaler,
    )..layout();
    final width = (labelPainter.width.ceilToDouble() + 24).clamp(
      0.0,
      overlay.size.width - media.padding.horizontal - 32,
    );
    labelPainter.dispose();
    final rowHeight = media.textScaler.scale(20) + 28;
    final height = rowHeight * 4 + 8;
    final left = (anchor.dx + button.size.width - width).clamp(
      media.padding.left + 16,
      overlay.size.width - media.padding.right - width - 16,
    );
    final top = (anchor.dy + button.size.height + 4).clamp(
      media.padding.top + 8,
      overlay.size.height - media.padding.bottom - height - 8,
    );
    final action = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: YanJiMotion.durationOf(context),
      transitionBuilder: (_, animation, secondaryAnimation, child) => child,
      pageBuilder: (menuContext, animation, secondaryAnimation) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation.drive(CurveTween(curve: YanJiMotion.curve)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: width,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (value, label) in [
                            ('edit', '修改名称'),
                            ('up', '上移'),
                            ('down', '下移'),
                            ('archive', '删除'),
                          ])
                            SizedBox(
                              height: rowHeight,
                              child: GlassTextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  minimumSize: Size.zero,
                                  textStyle: labelStyle,
                                ),
                                onPressed: () =>
                                    Navigator.pop(menuContext, value),
                                child: Text(label),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'edit') {
      await edit(context, subject: subject);
    } else if (action == 'up') {
      await saveAction(context, () => app.moveSubject(subject, -1));
    } else if (action == 'down') {
      await saveAction(context, () => app.moveSubject(subject, 1));
    } else {
      await saveAction(context, () => app.deleteSubject(subject));
    }
  }

  Future<void> confirmPermanentDelete(
    BuildContext context,
    Subject subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassAlertDialog(
        title: const Text('彻底删除科目？'),
        content: Text('「${subject.name}」及其二级科目将无法恢复，关联任务和学习记录也将从应用中移除。'),
        actions: [
          GlassTextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          GlassFilledButton(
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
      MotionSection(
        child: app.subjects.isEmpty
            ? const EmptyMessage('还没有科目', '点击右上角添加一级科目。')
            : const SizedBox.shrink(),
      ),
      MotionList(
        children: app.subjects
            .where((s) => s.parentSubjectId == null && app.isSubjectVisible(s))
            .map(
              (parent) => ExpansionTile(
                key: PageStorageKey('subject-${parent.id}'),
                minTileHeight: 48,
                tilePadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Expanded(child: Text(parent.name)),
                    actions(context, parent),
                  ],
                ),
                childrenPadding: const EdgeInsets.only(left: 16, bottom: 12),
                children: [
                  MotionList(
                    children: app.subjects
                        .where(
                          (s) =>
                              s.parentSubjectId == parent.id && s.archived == 0,
                        )
                        .map(
                          (child) => ListTile(
                            key: ValueKey(child.id),
                            minTileHeight: 40,
                            minVerticalPadding: 0,
                            contentPadding: EdgeInsets.zero,
                            title: Text(child.name),
                            onTap: () => edit(context, subject: child),
                            trailing: actions(context, child),
                          ),
                        )
                        .toList(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GlassTextButton.icon(
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
            )
            .toList(),
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
          MotionSection(
            child: !app.subjects.any((s) => s.archived == 1)
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: YanJiCaption('暂无已删除的科目'),
                  )
                : const SizedBox.shrink(),
          ),
          MotionList(
            children: app.subjects
                .where((s) => s.archived == 1)
                .map(
                  (subject) => ListTile(
                    key: ValueKey(subject.id),
                    title: Text(subject.name),
                    subtitle: subject.parentSubjectId == null
                        ? null
                        : Text(
                            app.subject(subject.parentSubjectId)?.name ?? '',
                          ),
                    trailing: PopupMenuButton<String>(
                      tooltip: '已删除科目操作：${subject.name}',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'restore') {
                          saveAction(
                            context,
                            () => app.restoreSubject(subject),
                          );
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
                )
                .toList(),
          ),
        ],
      ),
    ],
  );
}
