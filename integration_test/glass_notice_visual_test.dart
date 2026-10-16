import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/design/glass/glass_notice.dart';
import 'package:yanji/design/yanji_theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('notice stays legible over content and bends toward held edge', (
    tester,
  ) async {
    late BuildContext page;
    await tester.pumpWidget(
      MaterialApp(
        theme: yanjiThemeFor(Brightness.light),
        home: Scaffold(
          body: SafeArea(
            child: Builder(
              builder: (context) {
                page = context;
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '研迹',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('今天的努力，变成看得见的轨迹。'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    if (!page.mounted) return;
    GlassNotice.show(page, '暂无已绑定设备');
    await tester.pumpAndSettle();
    await binding.takeScreenshot('glass-notice-opaque');
    final transform = find.byKey(const Key('glass-elastic-transform'));
    final rect = tester.getRect(transform);
    final left = await tester.startGesture(
      Offset(rect.left + 8, rect.center.dy),
    );
    await left.moveBy(const Offset(0, 28));
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.widget<Transform>(transform).transform.entry(1, 0),
      lessThan(0),
    );
    await binding.takeScreenshot('glass-notice-left-held');
    await left.up();
    await tester.pumpAndSettle();
    final right = await tester.startGesture(
      Offset(rect.right - 8, rect.center.dy),
    );
    await right.moveBy(const Offset(0, 28));
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.widget<Transform>(transform).transform.entry(1, 0),
      greaterThan(0),
    );
    await binding.takeScreenshot('glass-notice-right-held');
    await right.up();
    expect(tester.takeException(), isNull);
  });
}
