import 'package:integration_test/integration_test.dart';

import '../test/widget/startup_reveal_test.dart' as acceptance;

// Exercise the same interaction and pixel assertions using the device's real
// Flutter raster backend. No database or platform identity is opened here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  acceptance.main();
}
