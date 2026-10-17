import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/design/glass/glass_controls.dart';
import 'package:yanji/design/glass/glass_dropdown_form_field.dart';
import 'package:yanji/design/glass/glass_floating_surface.dart';
import 'package:yanji/design/glass/glass_notice.dart';
import 'package:yanji/design/glass/glass_segmented_control.dart';
import 'package:yanji/design/glass/liquid_glass_quality.dart';
import 'package:yanji/design/glass/liquid_glass_surface.dart';
import 'package:yanji/design/yanji_theme.dart';

import 'support/navigation_capture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'shared material follows the renderer across all glass controls',
    (tester) async {
      await binding.convertFlutterSurfaceToImage();
      final quality = await YanjiGlassQuality.resolve();
      final supported = ui.ImageFilter.isShaderFilterSupported;
      expect(defaultTargetPlatform.name, isIn(['ohos', 'android', 'iOS']));
      expect(isHarmonyOS, defaultTargetPlatform.name == 'ohos');
      expect(
        quality,
        supportsGlassShaders
            ? YanjiGlassQuality.high
            : YanjiGlassQuality.reduced,
      );
      final output = Directory(
        '${(await getAppSupportDirectory()).path}/shared-glass-acceptance',
      );
      await output.create(recursive: true);
      Future<void> shot(String name) async {
        await File('${output.path}/$name.png').writeAsBytes(
          await captureNavigationFrame(binding, tester, name),
          flush: true,
        );
        expect(tester.takeException(), isNull);
      }

      for (final brightness in Brightness.values) {
        var selected = 0;
        var subject = '数学';
        var confirmations = 0;
        late BuildContext page;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: yanjiThemeFor(brightness),
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _BackdropGrid(brightness)),
                  ),
                  SafeArea(
                    child: Center(
                      child: SizedBox(
                        width: 320,
                        child: StatefulBuilder(
                          builder: (context, set) {
                            page = context;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const YanjiGlassSurface(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('共用玻璃面板'),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GlassDropdownFormField<String>(
                                  key: const Key('shared-subject'),
                                  initialValue: subject,
                                  items: const [
                                    DropdownMenuItem(
                                      value: '数学',
                                      child: Text('数学'),
                                    ),
                                    DropdownMenuItem(
                                      value: '英语',
                                      child: Text('英语'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      set(() => subject = value!),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 42,
                                  child: GlassSegmentedControl(
                                    labels: const ['日', '周', '月'],
                                    selected: selected,
                                    onSelected: (value) {
                                      set(() => selected = value);
                                      return true;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const GlassFloatingSurface(
                                  padding: EdgeInsets.all(20),
                                  child: Text('信息浮层 · 背景模糊'),
                                ),
                                const SizedBox(height: 20),
                                GlassFilledButton(
                                  onPressed: () => showDialog<void>(
                                    context: context,
                                    builder: (dialog) => GlassAlertDialog(
                                      title: const Text('玻璃弹窗'),
                                      content: const Text('此处只使用合成验收内容。'),
                                      actions: [
                                        GlassTextButton(
                                          onPressed: () {
                                            confirmations++;
                                            Navigator.pop(dialog);
                                          },
                                          child: const Text('确定'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: const Text('打开弹窗'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await shot('${brightness.name}-overview');
        final sharedLayer = tester.widget<LiquidGlassLayer>(
          find.byType(LiquidGlassLayer).first,
        );
        expect(sharedLayer.fake, !supportsGlassShaders);
        await tester.tap(find.byKey(const Key('shared-subject')));
        await shot('${brightness.name}-dropdown');
        await tester.tap(find.text('英语').last);
        await tester.pumpAndSettle();
        expect(subject, '英语');
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('日')),
        );
        await gesture.moveBy(const Offset(24, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(150, 0));
        await tester.pump(const Duration(milliseconds: 300));
        await shot('${brightness.name}-segment-held');
        await gesture.up();
        await tester.pumpAndSettle();
        expect(selected, 1);
        await tester.tap(find.text('打开弹窗'));
        await shot('${brightness.name}-dialog');
        await tester.tap(find.text('确定'));
        await tester.pumpAndSettle();
        expect(confirmations, 1);
        if (!page.mounted) {
          fail('The acceptance page was unexpectedly unmounted');
        }
        GlassNotice.show(page, '共用浮层验收');
        await shot('${brightness.name}-notice');
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      }
      final report = {
        'platform': defaultTargetPlatform.name,
        'shaderFiltersSupported': supported,
        'quality': quality.name,
        'capturedShaderBackend': usesCapturedGlass,
        'fullRefractionVerified': false,
        'compatibilityControlsPassed': true,
        'themes': ['dark', 'light'],
        'components': [
          'shared surface',
          'dropdown',
          'segmented control',
          'dialog',
          'button',
          'floating surface',
          'notice',
        ],
      };
      await File(
        '${output.path}/result.json',
      ).writeAsString(jsonEncode(report), flush: true);
      debugPrint('YANJI_HARMONY_SHARED_GLASS_PASS ${jsonEncode(report)}');
    },
  );
}

class _BackdropGrid extends CustomPainter {
  _BackdropGrid(this.brightness);
  final Brightness brightness;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..color = (brightness == Brightness.dark ? Colors.white : Colors.blueGrey)
          .withValues(alpha: .35);
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_BackdropGrid old) => old.brightness != brightness;
}
