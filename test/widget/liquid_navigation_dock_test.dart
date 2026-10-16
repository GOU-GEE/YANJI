import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';
import 'package:yanji/design/glass/coolapk_navigation_style.dart';
import 'package:yanji/design/glass/coolapk_navigation_surface.dart';

void main() {
  testWidgets('compact dock grows the lens while glyphs keep their size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LiquidNavigationDock(
              selected: 0,
              vertical: false,
              capability: NavigationGlassCapability.translucent,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final dock = find.byKey(const Key('navigation-dock'));
    expect(tester.getSize(dock).width, 272);
    final normal = find.byKey(const ValueKey('nav-/'));
    final icon = find.descendant(
      of: normal,
      matching: find.byIcon(Icons.today_outlined),
    );
    final label = find.descendant(of: normal, matching: find.text('今日'));
    final iconRect = tester.getRect(icon), textRect = tester.getRect(label);
    final captures = List.generate(
      3,
      (i) => find.byKey(ValueKey('nav-accent-$i')),
    );
    final captureSizes = captures.map((f) => tester.getRect(f).size).toList();
    final gesture = await tester.startGesture(tester.getCenter(icon));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getRect(icon), iconRect);
    expect(tester.getRect(label), textRect);
    for (var i = 0; i < 3; i++) {
      expect(tester.getRect(captures[i]).size, captureSizes[i]);
    }
    final surface = find.byType(CoolapkNavigationSurface);
    final heldSurface = tester.widget<CoolapkNavigationSurface>(surface);
    final bar = CoolapkNavigationStyle.containerBounds(
      tester.getSize(dock),
      heldSurface.barScale,
    );
    expect(bar.left - heldSurface.thumb.left, greaterThan(4));
    expect(heldSurface.thumb.center.dy, closeTo(bar.center.dy, .001));
    final clip = tester.widget<ClipPath>(
      find.descendant(of: surface, matching: find.byType(ClipPath)).first,
    );
    expect(
      clip.clipper!.getClip(tester.getSize(dock)).getBounds().width,
      greaterThan(tester.getSize(dock).width),
    );
    expect(
      clip.clipper!.getClip(tester.getSize(dock)).getBounds().height,
      greaterThan(70),
    );
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(110, 0));
    await tester.pump(const Duration(milliseconds: 500));
    for (var i = 0; i < 3; i++) {
      expect(tester.getRect(captures[i]).size, captureSizes[i]);
    }
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final vertical in [false, true]) {
    for (final rtl in [false, true]) {
      testWidgets(
        'tap, hold, reverse, cancel and settle vertical=$vertical rtl=$rtl',
        (tester) async {
          var selected = 0, commits = 0;
          await tester.pumpWidget(
            MaterialApp(
              home: Directionality(
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                child: Scaffold(
                  body: Center(
                    child: StatefulBuilder(
                      builder: (_, update) => LiquidNavigationDock(
                        selected: selected,
                        vertical: vertical,
                        capability: NavigationGlassCapability.translucent,
                        onSelected: (i) => update(() {
                          selected = i;
                          commits++;
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final lens = find.byKey(const Key('liquid-indicator'));
          Offset center() => tester.getCenter(lens);
          final initial = center();
          await tester.tap(find.byKey(const ValueKey('nav-/profile')));
          await tester.pumpAndSettle();
          expect(selected, 2);
          expect(commits, 1);
          expect((center() - initial).distance, greaterThan(100));
          expect(
            tester
                .getRect(lens)
                .contains(
                  tester.getCenter(find.byKey(const ValueKey('nav-/profile'))),
                ),
            isTrue,
          );
          final start = center();
          final gesture = await tester.startGesture(start);
          await tester.pump(const Duration(milliseconds: 110));
          await tester.pump(const Duration(milliseconds: 500));
          CoolapkNavigationSurface surface() =>
              tester.widget<CoolapkNavigationSurface>(
                find.byType(CoolapkNavigationSurface),
              );
          expect(surface().press, closeTo(1, .001));
          final bar = CoolapkNavigationStyle.containerBounds(
            tester.getSize(find.byKey(const Key('navigation-dock'))),
            surface().barScale,
          );
          if (!vertical) {
            expect(
              rtl
                  ? bar.left - surface().thumb.left
                  : surface().thumb.right - bar.right,
              greaterThan(4),
            );
            expect(surface().thumb.center.dy, closeTo(bar.center.dy, .001));
          }
          final direction = rtl && !vertical ? 1.0 : -1.0;
          Offset delta(double n) =>
              vertical ? Offset(0, -n) : Offset(direction * n, 0);
          await gesture.moveBy(delta(24));
          await tester.pump();
          await gesture.moveBy(delta(vertical ? 135 : 310));
          await tester.pump(const Duration(milliseconds: 100));
          expect(commits, 1);
          await tester.pump(const Duration(milliseconds: 900));
          final held = center();
          final heldRect = surface().thumb;
          await tester.pump(const Duration(milliseconds: 400));
          expect((center() - held).distance, lessThan(.01));
          expect((surface().thumb.width - heldRect.width).abs(), lessThan(.01));
          // Reverse before releasing, without routing mid-drag.
          await gesture.moveBy(-delta(vertical ? 135 : 310));
          await tester.pump(const Duration(milliseconds: 80));
          expect((center() - start).distance, lessThan(5));
          await gesture.moveBy(delta(vertical ? 135 : 310));
          await tester.pump(const Duration(milliseconds: 80));
          await gesture.cancel();
          await tester.pumpAndSettle();
          expect(selected, 2);
          expect(commits, 1);
          expect((center() - start).distance, lessThan(.01));
          final commit = await tester.startGesture(center());
          await commit.moveBy(delta(24));
          await tester.pump();
          await commit.moveBy(delta(vertical ? 135 : 310));
          await tester.pump(const Duration(milliseconds: 80));
          await commit.up();
          await tester.pumpAndSettle();
          expect(selected, 0);
          expect(commits, 2);
          expect(surface().press, closeTo(0, .001));
          expect(
            tester
                .getRect(lens)
                .contains(
                  tester.getCenter(find.byKey(const ValueKey('nav-/'))),
                ),
            isTrue,
          );
          // Restart while the tap spring is still running.
          await tester.tap(find.byKey(const ValueKey('nav-/statistics')));
          await tester.pump(const Duration(milliseconds: 30));
          await tester.tap(find.byKey(const ValueKey('nav-/profile')));
          await tester.pumpAndSettle();
          expect(selected, 2);
          expect(commits, 4);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('signed velocity reverses deformation without disabling optics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LiquidNavigationDock(
              selected: 1,
              vertical: false,
              capability: NavigationGlassCapability.translucent,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    CoolapkNavigationSurface surface() =>
        tester.widget<CoolapkNavigationSurface>(
          find.byType(CoolapkNavigationSurface),
        );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('liquid-indicator'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    final stationaryWidth = surface().thumb.width;
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(surface().thumb.width, greaterThan(stationaryWidth));
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(surface().thumb.width, lessThan(stationaryWidth));
    expect(surface().press, closeTo(1, .001));
    await gesture.cancel();
    await tester.pumpAndSettle();
  });
  testWidgets(
    'three modes, narrow layout, reduced motion and vertical axis rejection',
    (tester) async {
      var selected = 0;
      for (final mode in NavigationGlassCapability.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 210,
                    child: StatefulBuilder(
                      builder: (_, update) => LiquidNavigationDock(
                        selected: selected,
                        vertical: false,
                        capability: mode,
                        onSelected: (i) => update(() => selected = i),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-/profile')));
        await tester.pump();
        expect(selected, 2);
        expect(tester.hasRunningAnimations, isFalse);
        final start = tester.getCenter(
          find.byKey(const Key('liquid-indicator')),
        );
        await tester.dragFrom(start, const Offset(0, -100));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const Key('navigation-dock'))).width,
          210,
        );
      }
    },
  );
}
