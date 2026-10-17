import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/app/startup_reveal.dart';
import 'package:yanji/main.dart' as app;

import '../test/widget/startup_reveal_test.dart' as acceptance;

class _Lifecycle extends WidgetsBindingObserver {
  bool left = false;
  bool returned = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      left = true;
    }
    if (left && state == AppLifecycleState.resumed) returned = true;
  }
}

/// Run with YANJI_PREVIEW=true. The host backgrounds and foregrounds this
/// process after WARM_READY; no simulated lifecycle events are injected here.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  acceptance.main();
  testWidgets(
    'real preview app reveals, navigates and survives native resume',
    (tester) async {
      expect(const bool.fromEnvironment('YANJI_PREVIEW'), isTrue);
      await app.main();
      final today = find.byKey(const ValueKey('nav-/'));
      for (var i = 0; i < 600; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (today.evaluate().isNotEmpty &&
            find.byKey(StartupReveal.overlayKey).evaluate().isEmpty) {
          break;
        }
      }
      expect(today, findsOneWidget);
      expect(find.byKey(StartupReveal.overlayKey), findsNothing);
      await tester.tap(find.byKey(const ValueKey('nav-/profile')));
      await tester.pumpAndSettle();
      expect(find.text('设备与同步'), findsWidgets);
      final lifecycle = _Lifecycle();
      binding.addObserver(lifecycle);
      addTearDown(() => binding.removeObserver(lifecycle));
      // ignore: avoid_print
      print('YANJI_STARTUP_WARM_READY pid=$pid');
      for (var i = 0; i < 600 && !lifecycle.returned; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        expect(find.byKey(StartupReveal.overlayKey), findsNothing);
      }
      expect(lifecycle.left, isTrue, reason: 'Host must background the app');
      expect(
        lifecycle.returned,
        isTrue,
        reason: 'Host must resume the same app',
      );
      await tester.pumpAndSettle();
      expect(find.text('设备与同步'), findsWidgets);
      expect(find.byKey(StartupReveal.overlayKey), findsNothing);
      await tester.tap(today);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // ignore: avoid_print
      print('YANJI_STARTUP_NATIVE_RESUME_PASS pid=$pid');
    },
  );
}
