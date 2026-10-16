import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/design/yanji_theme.dart';
import 'package:yanji/features/shared.dart';
import 'package:yanji/features/subjects_page.dart';

import '../support/identities.dart';

void main() {
  testWidgets(
    'subject lists preserve expansion without reading it as scroll offset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      late StudyAppController app;
      await tester.runAsync(() async {
        app = await StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
        );
        await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
        await app.saveSubject(name: '高等数学', parentId: app.subjects.single.id);
      });
      final bucket = PageStorageBucket();
      Widget page() => MaterialApp(
        theme: yanjiThemeFor(Brightness.light),
        home: RootPageScrollMemory(bucket: bucket, child: SubjectsPage(app)),
      );
      try {
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('数学'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('高等数学'), findsOneWidget);
          if (i < 2) {
            await tester.tap(find.text('数学'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('高等数学'), findsNothing);
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('高等数学'), findsOneWidget);
        for (final name in ['数学', '高等数学']) {
          await tester.tap(find.byTooltip('科目操作：$name'));
          await tester.pumpAndSettle();
          final editRect = tester.getRect(find.text('修改名称'));
          for (final label in ['上移', '下移', '删除']) {
            expect(find.text(label).hitTestable(), findsOneWidget);
            final rect = tester.getRect(find.text(label));
            expect(rect.center.dx, closeTo(editRect.center.dx, 1));
            expect(rect.top, greaterThan(editRect.bottom));
            expect(
              rect.right,
              lessThanOrEqualTo(tester.view.physicalSize.width),
            );
          }
          await tester.tap(find.text('修改名称'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<TextField>(find.byKey(const Key('subject-name')))
                .controller!
                .text,
            name,
          );
          await tester.tap(find.text('取消'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(find.text('已删除的科目'));
        await tester.tap(find.text('已删除的科目'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('暂无已删除的科目'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
        await tester.runAsync(db.close);
      }
    },
  );
}
