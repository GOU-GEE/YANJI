import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _WelcomePage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class YanJiApp extends ConsumerWidget {
  const YanJiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: '研迹 YanJi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF47675A)),
      scaffoldBackgroundColor: const Color(0xFFF8F8F4),
    ),
    routerConfig: ref.watch(routerProvider),
  );
}

// Temporary bootstrap screen; onboarding is implemented after the data gate.
class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('研迹', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text('YanJi', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 32),
                Text(
                  '不只记录学了多久，\n更记录整个备考过程。',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                const Text('学习记录功能正在准备中。'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
