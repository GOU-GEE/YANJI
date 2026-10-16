import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/navigation_capture.dart';

import 'package:path_provider/path_provider.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/design/glass/liquid_glass_surface.dart';
import 'package:yanji/design/glass/coolapk_navigation_surface.dart';

import '../test/support/identities.dart';

/// Uses an isolated in-memory database, leaving the installed user's data intact.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real renderer: dock, scrolling, spring, light/dark and landscape', (
    tester,
  ) async {
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }
    final db = AppDatabase(NativeDatabase.memory());
    var now = DateTime.utc(2026, 9, 27, 8);
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      now: () => now,
    );
    await app.onboard(
      name: '2028 考研',
      date: '2028-12-23',
      subjectNames: ['数学', '英语', '政治'],
    );
    for (var i = 0; i < 18; i++) {
      await app.saveTask(
        title: '复习 ${i + 1} · 整理知识点与错题',
        subjectId: app.subjects[i % 3].id,
        date: app.today,
        estimatedSeconds: 1800,
        priority: i % 3,
      );
    }
    for (var i = 0; i < 3; i++) {
      await app.startStudy(app.subjects[i].id);
      now = now.add(Duration(minutes: 35 + i * 15));
      await app.stopStudy();
    }
    final output = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/liquid-glass-preview',
    );
    await output.create(recursive: true);
    final brightness = ValueNotifier(Brightness.light);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) async => app)],
        child: ValueListenableBuilder<Brightness>(
          valueListenable: brightness,
          builder: (context, value, _) => MediaQuery(
            data: MediaQueryData.fromView(tester.view)
                .copyWith(platformBrightness: value),
            child: const YanJiApp(),
          ),
        ),
      ),
    );
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      await File('${output.path}/$name.png')
          .writeAsBytes(await captureNavigationFrame(binding, tester, name));
      expect(tester.takeException(), isNull);
    }

    Future<void> tap(String path) async {
      if (find.byType(Scrollable).evaluate().isNotEmpty) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 80));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(ValueKey('nav-$path')));
      await tester.pumpAndSettle();
    }

    try {
      await tester.pumpAndSettle();
      // The simulator must exercise the real optical path, not a mock renderer.
      expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
      for (final mode in Brightness.values) {
        brightness.value = mode;
        await tester.pumpAndSettle();
        await tap('/');
        // Theme changes and route returns preserve page scroll memory. Restore
        // this fixture explicitly before exercising controls in the top header.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
        await tester.pumpAndSettle();
        await shot('${mode.name}-today');
        await tester.tap(find.byKey(const Key('today-start')));
        await shot('${mode.name}-study-dialog');
        await tester.tap(find.byKey(const Key('study-subject')));
        await shot('${mode.name}-study-subject-dropdown');
        await tester.tap(find.text('英语').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cancel-study')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('choose-exam-year')));
        await shot('${mode.name}-exam-dialog');
        await tester.tap(find.byKey(const Key('exam-year')));
        await shot('${mode.name}-exam-year-dropdown');
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('添加任务'));
        await shot('${mode.name}-task-dialog');
        await tester.tap(find.byTooltip('关闭'));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -450),
        );
        await shot('${mode.name}-today-scroll');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 80));
        await tester.pumpAndSettle();
        // Hold the real lens between tabs so glyphs cross its optical rim.
        final bubble = find.byKey(const Key('liquid-indicator'));
        final gesture = await tester.startGesture(tester.getCenter(bubble));
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump(const Duration(milliseconds: 80));
        expect(
          tester
              .widget<CoolapkNavigationSurface>(
                find.byType(CoolapkNavigationSurface),
              )
              .press,
          greaterThan(.6),
          reason: 'Deliberate dragging must keep the rim refractive.',
        );
        await gesture.moveBy(const Offset(21, 0));
        await tester.pump(const Duration(milliseconds: 80));
        await tester.pump(const Duration(milliseconds: 600));
        expect(
          tester
              .widget<CoolapkNavigationSurface>(
                find.byType(CoolapkNavigationSurface),
              )
              .press,
          closeTo(1, .0001),
        );
        await shot('${mode.name}-bubble-held-still');
        await File('${output.path}/${mode.name}-bubble-mid-drag.png')
            .writeAsBytes(
              await captureNavigationFrame(
                binding,
                tester,
                '${mode.name}-bubble-mid-drag',
              ),
            );
        for (var frame = 1; frame <= 4; frame++) {
          await gesture.moveBy(const Offset(25, 0));
          await tester.pump(const Duration(milliseconds: 80));
          await File('${output.path}/${mode.name}-bubble-drag-$frame.png')
              .writeAsBytes(
                await captureNavigationFrame(
                  binding,
                  tester,
                  '${mode.name}-bubble-drag-$frame',
                ),
              );
          expect(tester.takeException(), isNull);
        }
        await gesture.cancel();
        await tester.pumpAndSettle();

        await tap('/profile');
        await shot('${mode.name}-profile');
        final profileTile = find.text('我的科目');
        final tileDrag = await tester.startGesture(
          tester.getCenter(profileTile),
        );
        await tester.pump(const Duration(milliseconds: 120));
        await File('${output.path}/${mode.name}-profile-tile-pressed.png')
            .writeAsBytes(
              await captureNavigationFrame(
                binding,
                tester,
                '${mode.name}-profile-tile-pressed',
              ),
            );
        await tileDrag.moveBy(const Offset(28, 0));
        await tester.pump(const Duration(milliseconds: 80));
        final tileTransform = find.ancestor(
          of: profileTile,
          matching: find.byKey(const Key('glass-elastic-transform')),
        );
        expect(
          tester.widget<Transform>(tileTransform).transform.entry(0, 3),
          greaterThan(0),
        );
        await File('${output.path}/${mode.name}-profile-elastic-held.png')
            .writeAsBytes(
              await captureNavigationFrame(
                binding,
                tester,
                '${mode.name}-profile-elastic-held',
              ),
            );
        await tileDrag.cancel();
        await tester.pumpAndSettle();
        await tester.tap(find.text('我的科目'));
        await shot('${mode.name}-subjects-toolbar');
        await tester.tap(find.byTooltip('新增科目'));
        await shot('${mode.name}-subject-dialog');
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tap('/');
        await tap('/statistics');
        await shot('${mode.name}-statistics');
        await tester.scrollUntilVisible(
          find.byKey(const Key('subject-range')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.byKey(const Key('subject-range')));
        await shot('${mode.name}-range-selector');
        final range = find.byKey(const Key('subject-range'));
        final rangeDrag = await tester.startGesture(
          tester.getCenter(
            find.descendant(of: range, matching: find.text('日')),
          ),
        );
        await rangeDrag.moveBy(const Offset(30, 0));
        await tester.pump(const Duration(milliseconds: 30));
        await rangeDrag.moveBy(const Offset(56, 0));
        await tester.pump(const Duration(milliseconds: 600));
        expect(
          tester
              .widget<YanjiGlassSurface>(
                find.byKey(const Key('range-glass-indicator')),
              )
              .opticalActivity,
          1,
        );
        await shot('${mode.name}-range-glass-held');
        await rangeDrag.cancel();
        await tester.pumpAndSettle();
        await tester.tap(find.text('月'));
        await shot('${mode.name}-statistics-month');
        await tester.tap(find.text('自定义'));
        await shot('${mode.name}-custom-date-picker');
        Navigator.of(tester.element(find.byKey(const Key('custom-start-date'))))
            .pop();
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -220),
        );
        await shot('${mode.name}-statistics-scroll');
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -150),
        );
        await shot('${mode.name}-heatmap-edge');
      }
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      for (final mode in Brightness.values) {
        brightness.value = mode;
        await tester.pumpAndSettle();
        for (final path in ['/', '/profile', '/', '/statistics']) {
          await tap(path);
        }
        await shot('${mode.name}-landscape');
      }
    } finally {
      await SystemChrome.setPreferredOrientations([]);
      await tester.pumpWidget(const SizedBox());
      brightness.dispose();
      app.dispose();
      await db.close();
    }
  });
}
