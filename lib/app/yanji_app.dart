import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/study_app_controller.dart';
import '../features/onboarding_page.dart';
import '../features/statistics_page.dart';
import '../features/device_tree_page.dart';
import '../features/subjects_page.dart';
import '../features/tasks_pages.dart';
import '../features/timer_review_pages.dart';
import 'dependencies.dart';
import '../design/yanji_theme.dart';

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
                    const Text('请确认设备已解锁后重试。已有学习记录不会被清除。'),
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
  Future<void> updateProgress() async {
    try {
      await widget.app.tickTaskProgress();
    } catch (_) {
      /* Controller retains the save error for retry. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(updateProgress());
  }

  late final GoRouter router;
  late bool wasReady;
  void readinessChanged() {
    if (wasReady != widget.app.isReady) {
      wasReady = widget.app.isReady;
      router.refresh();
    }
  }

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
      redirect: (context, state) {
        if (!app.isReady) return '/onboarding';
        if (state.uri.path == '/onboarding') return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => listen(() => OnboardingPage(app)),
        ),
        ShellRoute(
          builder: (context, state, child) => listen(
            () => _AppShell(app: app, path: state.uri.path, child: child),
          ),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => listen(() => TodayPage(app)),
            ),
            GoRoute(
              path: '/tasks',
              builder: (context, state) => listen(() => TasksPage(app)),
            ),
            GoRoute(
              path: '/statistics',
              builder: (context, state) => listen(() => StatisticsPage(app)),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => listen(() => ProfilePage(app)),
            ),
          ],
        ),
        GoRoute(
          path: '/device-tree',
          builder: (context, state) => const DevicePage(),
        ),
        GoRoute(
          path: '/subjects',
          builder: (context, state) => listen(() => SubjectsPage(app)),
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
      ],
    );
  }

  @override
  void dispose() {
    progressTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.app.removeListener(readinessChanged);
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

class _AppShell extends StatelessWidget {
  const _AppShell({required this.app, required this.path, required this.child});
  final StudyAppController app;
  final String path;
  final Widget child;
  static const paths = ['/', '/statistics', '/profile'];
  static const labels = ['今天', '数据', '我的'];
  static const icons = [
    Icons.today_outlined,
    Icons.bar_chart_rounded,
    Icons.person_outline,
  ];
  @override
  Widget build(BuildContext context) {
    final index = paths.indexOf(path), selected = index < 0 ? 0 : index;
    if (MediaQuery.sizeOf(context).width >= YanJiLayout.railBreakpoint &&
        MediaQuery.sizeOf(context).height >= YanJiLayout.railMinHeight) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (i) => context.go(paths[i]),
              labelType: NavigationRailLabelType.all,
              destinations: List.generate(
                paths.length,
                (i) => NavigationRailDestination(
                  icon: Icon(icons[i]),
                  label: Text(labels[i]),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                child: child,
              ),
            ),
          ],
        ),
      );
    }
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        minimum: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          (MediaQuery.viewPaddingOf(context).bottom - 12).clamp(
            8.0,
            double.infinity,
          ),
        ),
        child: Align(
          heightFactor: 1,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: .10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: .65),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: .65),
                    ),
                  ),
                  child: Material(
                    key: const Key('navigation-dock'),
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: List.generate(paths.length, (i) {
                          final active = selected == i;
                          final duration =
                              MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 200);
                          return Expanded(
                            child: Semantics(
                              label: labels[i],
                              selected: active,
                              button: true,
                              child: Tooltip(
                                message: labels[i],
                                excludeFromSemantics: true,
                                child: InkWell(
                                  key: ValueKey('nav-${paths[i]}'),
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: () => context.go(paths[i]),
                                  child: SizedBox(
                                    height: 52,
                                    child: Center(
                                      child: AnimatedScale(
                                        scale: active ? 1.16 : 1,
                                        duration: duration,
                                        curve: Curves.easeOutCubic,
                                        child: AnimatedContainer(
                                          duration: duration,
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: active
                                                ? colors.primaryContainer
                                                      .withValues(alpha: .72)
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            icons[i],
                                            color: active
                                                ? colors.primary
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
