import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/features/profile_sync_status.dart';
import 'package:yanji/sync/files/automatic_sync_controller.dart';

class _SyncState extends ChangeNotifier implements AutomaticSyncController {
  @override
  String message = '已同步 0/1 台设备，仍有记录待同步';
  @override
  String? error;
  @override
  bool complete = false;
  void update() => notifyListeners();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets('only truncated sync text expands, scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ProfileSyncController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: ProfileSyncStatus(
                controller: controller,
                hasPeers: true,
                busy: false,
                onSync: () async {},
              ),
            ),
          ),
        ),
      );
      final text = find.byKey(const Key('profile-sync-message'));
      final collapsed = tester.getSize(text).height;
      void expectCenteredActions() {
        final arrow = tester.getCenter(
          find.byKey(const Key('profile-sync-expand')),
        );
        final sync = tester.getCenter(find.byKey(const Key('profile-sync')));
        final row = tester.getCenter(
          find.byKey(const Key('profile-sync-status')),
        );
        expect(arrow.dy, closeTo(sync.dy, .01));
        expect(arrow.dy, closeTo(row.dy, .01));
      }

      expect(find.text('稍后'), findsNothing);
      expectCenteredActions();
      expect(find.byKey(const Key('profile-sync-expand')), findsOneWidget);
      await tester.tap(text);
      await tester.pumpAndSettle();
      expect(tester.getSize(text).height, greaterThan(collapsed));
      expectCenteredActions();
      expect(
        tester
            .widget<Text>(
              find.descendant(of: text, matching: find.byType(Text)),
            )
            .maxLines,
        isNull,
      );
      await tester.tap(text);
      await tester.pumpAndSettle();
      expect(tester.getSize(text).height, collapsed);
      expectCenteredActions();
      expect(find.text('稍后'), findsNothing);
      expect(
        tester
            .widget<Text>(
              find.descendant(of: text, matching: find.byType(Text)),
            )
            .maxLines,
        1,
      );
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('short result has no expansion; sync survives leaving the page', (
    tester,
  ) async {
    final controller = ProfileSyncController();
    addTearDown(controller.dispose);
    final completed = Completer<void>();
    var calls = 0;
    Widget page() => MaterialApp(
      home: Scaffold(
        body: ProfileSyncStatus(
          controller: controller,
          hasPeers: true,
          busy: false,
          onSync: () {
            calls++;
            return completed.future;
          },
        ),
      ),
    );
    await tester.pumpWidget(page());
    await tester.tap(find.byKey(const Key('profile-sync')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile-sync')));
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
    completed.completeError(StateError('等待设备连接超时，请保持另一台设备的研迹打开后重试。'));
    await tester.pump();
    await tester.pumpWidget(page());
    expect(find.textContaining('等待设备连接超时'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    await controller.run(() async {});
    await tester.pump();
    expect(find.text('已同步到全部已配对设备'), findsOneWidget);
    expect(find.byKey(const Key('profile-sync-expand')), findsNothing);
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('profile-sync-message')))
          .onTap,
      isNull,
    );
    expect(find.byKey(const Key('profile-sync-later')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('automatic state changes replace a stale manual result', () async {
    final sync = _SyncState();
    final controller = ProfileSyncController()..bind(sync);
    await controller.run(() async {
      throw StateError('等待设备连接超时');
    });
    expect(controller.message(true), '等待设备连接超时');
    sync.complete = true;
    sync.message = '已同步到全部 1 台设备';
    sync.update();
    expect(controller.message(true), sync.message);
    controller.dispose();
    sync.dispose();
  });
}
