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
      await tester.binding.handlePopRoute();
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('enter-pairing-code')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final refresh = tester.getRect(
      find.byKey(const Key('refresh-pairing-code')),
    );
    final scan = tester.getRect(find.byKey(const Key('scan-pairing-qr-ready')));
    final copy = tester.getRect(find.byKey(const Key('copy-pairing-code')));
    final enter = tester.getRect(find.byKey(const Key('enter-pairing-code')));
    expect(refresh.top, closeTo(scan.top, 1));
    expect(copy.top, closeTo(enter.top, 1));
    expect(copy.top, greaterThan(refresh.bottom));
    expect(refresh.right, lessThan(scan.left));
    expect(copy.right, lessThan(enter.left));
    final first = tester.widget<QrImageView>(find.byType(QrImageView)).key;
    expect(first, isA<ValueKey<String>>());
    await tap(find.text('刷新配对口令'));
    final second = tester.widget<QrImageView>(find.byType(QrImageView)).key;
    expect(second, first);
    expect(find.byKey(const Key('enter-pairing-code')), findsOneWidget);
    for (var index = 0; index < 6; index++) {
      await tap(find.byKey(const Key('enter-pairing-code')));
      expect(find.byKey(const Key('pairing-code-input')), findsOneWidget);
      final paste = tester.getRect(find.text('粘贴'));
      final cancel = tester.getRect(find.text('取消'));
      final connect = tester.getRect(find.text('连接'));
      expect(paste.center.dy, closeTo(cancel.center.dy, 1));
      expect(cancel.center.dy, closeTo(connect.center.dy, 1));
      if (index.isEven) {
        await tap(find.text('取消'));
      } else {
        await tester.binding.handlePopRoute();
        await settle();
      }
      expect(tester.takeException(), isNull);
    }
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
