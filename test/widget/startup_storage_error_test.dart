import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';

void main() {
  for (final code in ['CREDENTIAL_KEY_MISSING', 'CREDENTIAL_UNAVAILABLE']) {
    testWidgets('startup displays the appropriate storage failure for $code', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith(
              (ref) => throw PlatformException(code: code),
            ),
          ],
          child: const YanJiApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('暂时无法打开研迹'), findsOneWidget);
      expect(
        find.text(
          code == 'CREDENTIAL_KEY_MISSING'
              ? '设备的安全身份已不可用。已有学习记录仍保留，请不要清除应用数据。'
              : '请确认设备已解锁后重试。已有学习记录不会被清除。',
        ),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
