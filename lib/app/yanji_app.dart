import 'package:flutter/rendering.dart' show ScrollDirection;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import '../core/platform/app_support_directory.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/yanji_motion.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import '../features/onboarding_page.dart';
import '../features/shared.dart';
import '../features/statistics_page.dart';
import '../features/device_tree_page.dart';
import '../features/subjects_page.dart';
import '../features/tasks_pages.dart';
import '../features/timer_review_pages.dart';
import '../features/target_goal.dart';
import '../features/oppo_fluid_cloud_debug_page.dart';
import '../features/honor_magic_capsule_debug_page.dart';
import 'dependencies.dart';
import '../design/yanji_theme.dart';
import '../design/glass/liquid_navigation_dock.dart';
import '../design/glass/yanji_glass_theme.dart';
import '../core/storage/platform_key_storage.dart';
import '../sync/pairing/device_pairing_coordinator.dart';
import '../sync/files/automatic_sync_controller.dart';
import '../features/profile_sync_status.dart';

ThemeData get yanjiTheme => yanjiThemeFor(Brightness.light);

class YanJiApp extends ConsumerWidget {
  const YanJiApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(appControllerProvider)
      .when(
        data: (app) => _ConfiguredApp(app),
        loading: () => MaterialApp(
          builder: yanjiSystemUiBuilder,
          debugShowCheckedModeBanner: false,
          theme: yanjiTheme,
          darkTheme: yanjiThemeFor(Brightness.dark),
          themeMode: ThemeMode.system,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('研迹', style: YanJiTypography.textTheme.headlineMedium),
                  SizedBox(height: YanJiSpacing.lg),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
        error: (error, stack) => MaterialApp(
          builder: yanjiSystemUiBuilder,
          debugShowCheckedModeBanner: false,
          theme: yanjiTheme,
          darkTheme: yanjiThemeFor(Brightness.dark),
          themeMode: ThemeMode.system,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(YanJiSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '暂时无法打开研迹',
                      style: YanJiTypography.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: YanJiSpacing.md),
                    Text(
                      error is PlatformException &&
                              error.code == 'CREDENTIAL_KEY_MISSING'
                          ? '设备的安全身份已不可用。已有学习记录仍保留，请不要清除应用数据。'
                          : '请确认设备已解锁后重试。已有学习记录不会被清除。',
                    ),
                    const SizedBox(height: YanJiSpacing.lg),
                    FilledButton(
                      onPressed: () => ref.invalidate(appControllerProvider),
                      child: const Text('重新尝试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ConfiguredApp extends StatefulWidget {
  const _ConfiguredApp(this.app);
  final StudyAppController app;
  @override
  State<_ConfiguredApp> createState() => _ConfiguredAppState();
}

class _ConfiguredAppState extends State<_ConfiguredApp>
    with WidgetsBindingObserver {
  Timer? progressTicker;
  DevicePairingCoordinator? pairingCoordinator;
  Future<DevicePairingCoordinator>? pairingOpening;
  AutomaticSyncController? automaticSync;
  Future<AutomaticSyncController>? syncOpening;
  final syncNavigatorKey = GlobalKey<NavigatorState>();
  final profileSync = ProfileSyncController();

  Future<AutomaticSyncController> openAutomaticSync() {
    final existing = automaticSync;
    if (existing != null) return Future.value(existing);
    return syncOpening ??=
        (() async {
          final coordinator = await openPairingCoordinator();
          final support = await getAppSupportDirectory();
          final sync = AutomaticSyncController(
            app: widget.app,
            backend:
                isHarmonyOS ||
                    const String.fromEnvironment('YANJI_SYNC_BACKEND') == 'dart'
                ? AutomaticSyncBackend.dartTls
                : AutomaticSyncBackend.embeddedSyncthing,
            pairing: coordinator,
            directory: Directory(
              p.join(support.path, 'sync', widget.app.identity.deviceId),
            ),
          );
          if (!mounted) {
            await sync.close();
            throw StateError('应用已经关闭');
          }
          automaticSync = sync;
          profileSync.bind(sync);
          sync.start();
          setState(() {});
          return sync;
        })().catchError((Object error) {
          syncOpening = null;
          throw error;
        });
  }

  Future<void> updateProgress() async {
    try {
      await widget.app.tickTaskProgress();
      final action = await widget.app.handlePendingLiveActivityAction();
      if ((action == 'open' || action == 'finish') &&
          mounted &&
          router.state.uri.path != '/timer') {
        // Keep the current app page underneath the timer. Replacing the route
        // here made a Live Activity deep link open the timer as the root page,
        // leaving users with no back button.
        unawaited(router.push('/timer'));
      }
    } catch (_) {
      /* Controller retains the save error for retry. */
    }
  }

  Future<void> initializeLiveActivity() async {
    await updateProgress();
    await widget.app.syncLiveActivity();
  }

  Future<DevicePairingCoordinator> openPairingCoordinator() {
    final current = pairingCoordinator;
    if (current != null) return Future.value(current);
    return pairingOpening ??=
        DevicePairingCoordinator.open(
          widget.app,
          PlatformTlsIdentityStorage(),
        ).then((value) {
          pairingCoordinator = value;
          return value;
        });
  }

  Future<void> syncPairedDevices() async {
    final sync = await openAutomaticSync();
    await sync.syncNow();
  }

  Future<void> warmPairingCoordinator() async {
    try {
      await openPairingCoordinator();
      await openAutomaticSync();
    } catch (_) {
      pairingOpening = null;
      // DevicePage and the sync button can retry after permissions/network
      // become available.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(widget.app.checkpointStudyProgress());
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(updateProgress());
      final coordinator = pairingCoordinator;
      if (coordinator != null) unawaited(coordinator.refreshDiscovery());
      unawaited(warmPairingCoordinator());
      final sync = automaticSync;
      if (sync != null) unawaited(sync.foreground());
    }
    if (state == AppLifecycleState.paused) {
      final sync = automaticSync;
      if (sync != null) unawaited(sync.background());
    }
    if (state == AppLifecycleState.detached) {
      unawaited(widget.app.finishStudyForProcessExit());
    }
  }

  late final GoRouter router;
  late bool wasReady;
  void readinessChanged() {
    if (wasReady != widget.app.isReady) {
      wasReady = widget.app.isReady;
      router.refresh();
    }
  }

  final rootScrollBucket = PageStorageBucket();

  Widget listen(Widget Function() builder) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, child) => builder(),
  );
  @override
  void initState() {
    super.initState();
    final app = widget.app;
    wasReady = app.isReady;
    app.addListener(readinessChanged);
    WidgetsBinding.instance.addObserver(this);
    progressTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(updateProgress()),
    );
    router = GoRouter(
      navigatorKey: syncNavigatorKey,
      redirect: (context, state) {
        final isActivityOpen =
            state.uri.path == '/open' ||
            state.uri.path == '/live-activity/open';
        final deferredActivityOpen =
            state.uri.queryParameters['ongoing'] == 'open';
        if (!app.isReady && state.uri.path != '/device-tree') {
          if (isActivityOpen) return '/onboarding?ongoing=open';
          if (deferredActivityOpen) return null;
          return '/onboarding';
        }
        if (state.uri.path == '/onboarding') {
          return deferredActivityOpen ? '/timer' : '/';
        }
        if (isActivityOpen) return '/timer';
        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => listen(() => OnboardingPage(app)),
        ),
        ShellRoute(
          builder: (context, state, child) => listen(
            () => _AppShell(
              app: app,
              path: state.uri.path,
              scrollBucket: rootScrollBucket,
              child: child,
            ),
          ),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => _rootPage(
                state.pageKey,
                context,
                child: listen(() => TodayPage(app)),
              ),
            ),
            GoRoute(
              path: '/tasks',
              builder: (context, state) => listen(() => TasksPage(app)),
            ),
            GoRoute(
              path: '/statistics',
              pageBuilder: (context, state) => _rootPage(
                state.pageKey,
                context,
                child: listen(() => StatisticsPage(app)),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => _rootPage(
                state.pageKey,
                context,
                child: listen(
                  () => ProfilePage(
                    app,
                    onSync: syncPairedDevices,
                    sync: automaticSync,
                    syncFeedback: profileSync,
                  ),
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/device-tree',
          builder: (context, state) => listen(
            () => DevicePage(
              app,
              coordinatorFactory: openPairingCoordinator,
              disposeCoordinator: false,
            ),
          ),
        ),
        GoRoute(
          path: '/subjects',
          builder: (context, state) => listen(() => SubjectsPage(app)),
        ),
        GoRoute(
          path: '/goal',
          builder: (context, state) => listen(() => TargetGoalPage(app)),
        ),
        GoRoute(
          path: '/task/new',
          builder: (context, state) => listen(() => TaskEditorPage(app)),
        ),
        GoRoute(
          path: '/task/:id',
          builder: (context, state) => listen(
            () => TaskEditorPage(app, taskId: state.pathParameters['id']),
          ),
        ),
        GoRoute(
          path: '/timer',
          builder: (context, state) => listen(() => TimerPage(app)),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) => listen(() => ReviewPage(app)),
        ),
        if (kDebugMode)
          GoRoute(
            path: '/debug/oppo-fluid-cloud',
            builder: (context, state) => const OppoFluidCloudDebugPage(),
          ),
        if (kDebugMode)
          GoRoute(
            path: '/debug/honor-magic-capsule',
            builder: (context, state) => const HonorMagicCapsuleDebugPage(),
          ),
      ],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(initializeLiveActivity());
      unawaited(warmPairingCoordinator());
    });
  }

  @override
  void dispose() {
    progressTicker?.cancel();
    profileSync.dispose();
    final sync = automaticSync;
    if (sync != null) unawaited(sync.close());
    WidgetsBinding.instance.removeObserver(this);
    widget.app.removeListener(readinessChanged);
    final coordinator = pairingCoordinator;
    if (coordinator != null) unawaited(coordinator.close());
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    builder: yanjiSystemUiBuilder,
    title: '研迹 YanJi',
    debugShowCheckedModeBanner: false,
    theme: yanjiTheme,
    darkTheme: yanjiThemeFor(Brightness.dark),
    themeMode: ThemeMode.system,
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
  );
}

CustomTransitionPage<void> _rootPage(
  LocalKey key,
  BuildContext context, {
  required Widget child,
}) => CustomTransitionPage<void>(
  key: key,
  transitionDuration: YanJiMotion.durationOf(context),
  reverseTransitionDuration: YanJiMotion.durationOf(context),
  transitionsBuilder: (context, animation, secondary, child) {
    if (YanJiMotion.reduced(context)) return child;
    final progress = animation.drive(CurveTween(curve: YanJiMotion.curve));
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .015),
          end: Offset.zero,
        ).animate(progress),
        child: child,
      ),
    );
  },
  child: child,
);

class _AppShell extends StatefulWidget {
  const _AppShell({
    required this.app,
    required this.path,
    required this.scrollBucket,
    required this.child,
  });
  final StudyAppController app;
  final String path;
  final Widget child;
  final PageStorageBucket scrollBucket;
  static const paths = ['/', '/statistics', '/profile'];
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  static const paths = _AppShell.paths;
  bool _scrollHidden = false;
  String get path => widget.path;
  Widget get child => widget.child;
  PageStorageBucket get scrollBucket => widget.scrollBucket;
  @override
  void didUpdateWidget(_AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _scrollHidden = false;
  }

  @override
  Widget build(BuildContext context) {
    final index = paths.indexOf(path), selected = index < 0 ? 0 : index;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final safe = MediaQuery.viewPaddingOf(context);
    final bottom = (safe.bottom - 12).clamp(8.0, double.infinity);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 100;
    final hidden = keyboardVisible || _scrollHidden;
    final dockTransition =
        MediaQuery.disableAnimationsOf(context) ||
            MediaQuery.accessibleNavigationOf(context)
        ? Duration.zero
        : Duration(milliseconds: hidden ? 175 : 225);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          YanjiDockClearance(
            bottom: landscape ? 0 : LiquidNavigationDock.height + bottom + 16,
            left: landscape ? LiquidNavigationDock.verticalWidth + 24 : 0,
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.depth != 0 ||
                    notification.direction == ScrollDirection.idle) {
                  return false;
                }
                final hide = notification.direction == ScrollDirection.reverse;
                if (_scrollHidden != hide) {
                  setState(() => _scrollHidden = hide);
                }
                return false;
              },
              child: RootPageScrollMemory(
                bucket: scrollBucket,
                child: RepaintBoundary(child: child),
              ),
            ),
          ),
          Positioned(
            left: landscape ? safe.left + 8 : 20,
            right: landscape ? null : 20,
            top: landscape ? safe.top + 8 : null,
            bottom: landscape ? safe.bottom + 8 : bottom,
            child: IgnorePointer(
              ignoring: hidden,
              child: TweenAnimationBuilder<double>(
                duration: dockTransition,
                curve: Curves.easeOutCubic,
                tween: Tween<double>(end: hidden ? 0 : 1),
                builder: (context, visibility, _) => Opacity(
                  opacity: visibility,
                  child: AnimatedSlide(
                    duration: dockTransition,
                    curve: Curves.easeOutCubic,
                    offset: hidden
                        ? (landscape
                              ? const Offset(-.45, 0)
                              : const Offset(0, .45))
                        : Offset.zero,
                    child: AnimatedScale(
                      duration: dockTransition,
                      curve: Curves.easeOutCubic,
                      scale: hidden ? .92 : 1,
                      child: Align(
                        alignment: landscape
                            ? Alignment.centerLeft
                            : Alignment.bottomCenter,
                        child: LiquidNavigationDock(
                          selected: selected,
                          vertical: landscape,
                          // Opacity uses an offscreen layer while fading. Its
                          // backdrop filters must not sample that layer itself.
                          refractBackdrop: visibility == 1,
                          onSelected: (i) => context.go(paths[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
