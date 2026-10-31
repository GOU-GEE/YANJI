import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yanji/core/platform/app_support_directory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'HarmonyOS native scanner decodes a generated pairing QR fixture',
    (_) async {
      const payload = 'yanji-harmonyos-qr-acceptance-v1';
      final picture = ui.PictureRecorder();
      final canvas = ui.Canvas(picture)
        ..drawColor(const ui.Color(0xffffffff), ui.BlendMode.src);
      canvas.translate(32, 32);
      QrPainter(
        data: payload,
        version: QrVersions.auto,
      ).paint(canvas, const ui.Size(448, 448));
      final image = await picture.endRecording().toImage(512, 512);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File(
        '${(await getAppSupportDirectory()).path}/harmonyos-qr-fixture.png',
      );
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      final scanner = MobileScannerController(
        autoStart: false,
        formats: const [BarcodeFormat.qrCode],
      );
      try {
        final result = await scanner
            .analyzeImage(file.path, formats: const [BarcodeFormat.qrCode])
            .timeout(const Duration(seconds: 30));
        expect(
          result?.barcodes.map((barcode) => barcode.rawValue),
          contains(payload),
        );
        debugPrint('YANJI_HARMONY_QR_DECODE_PASS');
      } finally {
        await scanner.dispose();
      }
    },
  );
}
