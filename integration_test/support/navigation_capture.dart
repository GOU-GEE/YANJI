import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Android's converted ImageView can still expose the previously acquired
/// frame immediately after pump. Acquire once, then save the following frame;
/// never accept a stale image as evidence of a zero optical displacement.
Future<List<int>> captureNavigationFrame(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 160));
  await tester.pump();
  await binding.takeScreenshot('$name-sync');
  (binding.reportData!['screenshots'] as List<dynamic>).removeLast();
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 150));
  return binding.takeScreenshot(name);
}
