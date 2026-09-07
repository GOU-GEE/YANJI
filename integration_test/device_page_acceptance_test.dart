import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';
import 'package:yanji/main.dart' as application;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('native device page creates and replaces a secure invitation', (
    tester,
  ) async {
    await application.main();

    Future<void> settle() async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    Future<void> tap(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          100,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await settle();
    }

    for (
      var index = 0;
      index < 100 && find.byType(YanJiApp).evaluate().isEmpty;
      index++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final container = ProviderScope.containerOf(
      tester.element(find.byType(YanJiApp)),
    );
    final app = await container.read(appControllerProvider.future);
    await settle();

    if (!app.isReady) {
      expect(find.byKey(const Key('join-existing-device')), findsOneWidget);
      await tap(find.byKey(const Key('join-existing-device')));
      expect(find.text('带回我的学习空间'), findsOneWidget);
      expect(find.byKey(const Key('scan-pairing-qr')), findsOneWidget);
      expect(find.byKey(const Key('enter-pairing-code')), findsOneWidget);
      await tester.pageBack();
      await settle();
      await tap(find.byKey(const Key('exam-date')));
      await tap(find.text('确定'));
      await tap(find.byKey(const Key('onboarding-next')));
      await tap(find.byKey(const Key('onboarding-next')));
      await tap(find.byKey(const Key('onboarding-next')));
      await settle();
    }

    expect(app.isReady, isTrue);
    await tap(find.byKey(const ValueKey('nav-/profile')));
    await tap(find.text('设备与同步'));
    for (
      var index = 0;
      index < 100 && find.byType(QrImageView).evaluate().isEmpty;
      index++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('添加另一台设备'), findsOneWidget);
    expect(find.textContaining('仅可使用一次'), findsOneWidget);
    expect(find.text('暂无其他设备。'), findsOneWidget);
    final first = tester.widget<QrImageView>(find.byType(QrImageView)).key;
    expect(first, isA<ValueKey<String>>());
    await tap(find.text('刷新配对口令'));
    final second = tester.widget<QrImageView>(find.byType(QrImageView)).key;
    expect(second, first);
    expect(find.byKey(const Key('enter-pairing-code')), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
