import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/features/statistics_page.dart';

import '../support/identities.dart';

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('profile device section, rename and inline sync at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      late StudyAppController app;
      const peerId = '01991f82-0000-7000-8000-000000000242';
      await tester.runAsync(() async {
        app = await StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000241', 61),
        );
        await app.onboard(
          name: '学习目标',
          date: '2028-12-20',
          subjectNames: ['数学'],
        );
        await app.ensureWorkspaceGenesis();
        final peer = await testIdentity(peerId, 62);
        await app.addTrustedPeer(
          deviceId: peerId,
          deviceName: '测试平板',
          platform: 'android',
          identityPublicKey: Uint8List.fromList(peer.publicKey.bytes),
          tlsCertificateSha256: Uint8List(32),
        );
      });
      final completed = Completer<void>();
      try {
        await tester.pumpWidget(
          MaterialApp(home: ProfilePage(app, onSync: () => completed.future)),
        );
        await tester.pumpAndSettle();
        expect(find.text('设备与同步'), findsOneWidget);
        expect(find.text('本机记录已保存，配对设备后可自动同步'), findsNothing);
        expect(find.text('测试平板'), findsOneWidget);
        expect(find.text('等待同步'), findsOneWidget);
        final add = tester.getRect(find.byKey(const Key('add-device')));
        final sync = tester.getRect(find.byKey(const Key('profile-sync')));
        expect(sync.top, greaterThan(add.bottom));
        expect(
          sync.left,
          greaterThan(
            tester.getRect(find.byKey(const Key('profile-sync-message'))).right,
          ),
        );
        expect(add.height, 40);
        expect(find.text('❌'), findsNothing);
        expect(find.text('重命名'), findsNothing);
        expect(
          tester.getCenter(find.text('测试平板')).dy,
          closeTo(tester.getCenter(find.text('等待同步')).dy, 1),
        );
        await tester.tap(find.byKey(const ValueKey('device-row-$peerId')));
        await tester.pumpAndSettle();
        expect(find.text('编辑设备'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '不应保存');
        await tester.tap(find.byKey(const Key('close-device-edit')));
        await tester.pumpAndSettle();
        expect(find.text('编辑设备'), findsNothing);
        expect(find.text('测试平板'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('device-row-$peerId')));
        await tester.pumpAndSettle();
        final deletion = tester.getRect(find.byKey(const Key('delete-device')));
        final completion = tester.getRect(
          find.byKey(const Key('complete-device-edit')),
        );
        expect(deletion.left, lessThan(completion.left));
        expect(deletion.center.dy, closeTo(completion.center.dy, 1));
        await tester.enterText(find.byType(TextField), '');
        await tester.tap(find.text('完成'));
        await tester.pumpAndSettle();
        expect(find.text('设备名称请输入一到四十个字'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '我的平板');
        await tester.tap(find.text('完成'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        });
        await tester.pumpAndSettle();
        expect(find.text('我的平板'), findsOneWidget);
        await tester.tap(find.byKey(const Key('profile-sync')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Sync no longer blocks the device list or opens a result overlay.
        await tester.tap(find.byKey(const ValueKey('device-row-$peerId')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('编辑设备'), findsOneWidget);
        await tester.tap(find.byKey(const Key('close-device-edit')));
        await tester.pump(const Duration(milliseconds: 400));
        completed.completeError(StateError('等待设备连接超时'));
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('等待设备连接超时'), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
        await tester.tap(find.byKey(const ValueKey('device-row-$peerId')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('delete-device')));
        await tester.pumpAndSettle();
        expect(find.text('删除“我的平板”？'), findsOneWidget);
        expect(find.textContaining('设备丢失'), findsNothing);
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        expect(find.text('编辑设备'), findsOneWidget);
        expect(
          app.trustedPeers
              .singleWhere((peer) => peer.deviceId == peerId)
              .active,
          isTrue,
        );
        await tester.tap(find.byKey(const Key('delete-device')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('删除').last);

        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(find.text('我的平板'), findsNothing);
        expect(find.text('暂无已配对设备'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
        await tester.runAsync(db.close);
      }
    });
  }
}
