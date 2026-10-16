import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/features/device_tree_page.dart';
import 'package:yanji/sync/pairing/device_pairing_coordinator.dart';
import 'package:yanji/sync/transport/lan_peer_discovery.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

import '../support/identities.dart';

class _Storage implements SecureTlsIdentityStorage {
  TlsIdentity? identity;
  @override
  Future<TlsIdentity?> readCurrent() async => identity;
  @override
  Future<TlsIdentity> installIfAbsent(TlsIdentity candidate) async =>
      identity ??= candidate;
}

class _Discovery implements LanPeerDiscovery {
  @override
  Future<void> advertise(String deviceId, int port) async {}
  @override
  Future<List<DiscoveredPeer>> find(Set<String> deviceIds) async => [];
  @override
  Future<void> close() async {}
}

void main() {
  for (final (width, scale) in [(320.0, 1.6), (390.0, 1.0)]) {
    testWidgets(
      'pairing progress blocks dismissal and merge actions stay on one row $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final databases = [
          AppDatabase(NativeDatabase.memory()),
          AppDatabase(NativeDatabase.memory()),
        ];
        final apps = <StudyAppController>[];
        final coordinators = <DevicePairingCoordinator>[];
        final opening = Completer<DevicePairingCoordinator>();
        await tester.runAsync(() async {
          for (var i = 0; i < 2; i++) {
            final app = await StudyAppController.open(
              databases[i],
              await testIdentity(
                '01991f82-0000-7000-8000-00000000023${i + 1}',
                i + 31,
              ),
            );
            apps.add(app);
            await app.onboard(
              name: '学习目标',
              date: '2027-12-20',
              subjectNames: ['数学'],
            );
            coordinators.add(
              await DevicePairingCoordinator.open(
                app,
                _Storage(),
                bindAddress: InternetAddress.loopbackIPv4,
                advertisedAddresses: ['127.0.0.1'],
                discovery: _Discovery(),
              ),
            );
            await app.ensureWorkspaceGenesis();
          }
        });
        try {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: DevicePage(
                apps[1],
                coordinatorFactory: () => opening.future,
                disposeCoordinator: false,
              ),
            ),
          );
          await tester.pump();
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.byType(LinearProgressIndicator), findsNothing);
          await tester.tapAt(const Offset(4, 4));
          await tester.pump();
          await tester.binding.handlePopRoute();
          await tester.pump();
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          for (final direction in [
            const Offset(-140, 0),
            const Offset(140, 0),
            const Offset(0, -140),
            const Offset(0, 140),
          ]) {
            final rect = tester.getRect(find.byType(CircularProgressIndicator));
            await tester.drag(find.text('正在准备设备配对'), direction);
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
            expect(
              tester.getRect(find.byType(CircularProgressIndicator)),
              rect,
            );
          }
          await tester.runAsync(() async {
            opening.complete(coordinators[1]);
            await Future<void>.delayed(const Duration(milliseconds: 150));
          });
          await tester.pumpAndSettle();
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text('已授权设备'), findsNothing);
          final invitation = await tester.runAsync(
            coordinators[0].createInvitation,
          );
          final enter = find.byKey(const Key('enter-pairing-code'));
          await tester.ensureVisible(enter);
          await tester.pumpAndSettle();
          await tester.tap(enter);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('pairing-code-input')),
            invitation!.encode(),
          );
          await tester.tap(find.text('连接'));
          await tester.pumpAndSettle();
          expect(find.text('合并记录并配对'), findsOneWidget);
          expect(find.text('保留记录并配对'), findsNothing);
          final keep = tester.getRect(find.text('保留记录'));
          final cancel = tester.getRect(find.text('取消'));
          expect(keep.center.dy, closeTo(cancel.center.dy, 1));
          expect(keep.left, greaterThan(cancel.right));
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('取消'));
          await tester.pumpAndSettle();
          expect(apps[1].workspace!.id, isNot(apps[0].workspace!.id));
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() async {
            for (final coordinator in coordinators) {
              await coordinator.close();
            }
            for (final app in apps) {
              app.dispose();
            }
            for (final database in databases) {
              await database.close();
            }
          });
        }
      },
    );
  }
}
