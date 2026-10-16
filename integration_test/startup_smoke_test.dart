import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';
import 'package:yanji/main.dart' as application;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('updated app opens its existing local workspace', (tester) async {
    await application.main();
    await tester.pump();
    final scope = find.byType(YanJiApp).first;
    final container = ProviderScope.containerOf(
      tester.element(scope),
      listen: false,
    );
    final app = await container.read(appControllerProvider.future);
    expect(app.error, isNull);
    await tester.pump();
    expect(find.text('暂时无法打开研迹'), findsNothing);
  });
}
