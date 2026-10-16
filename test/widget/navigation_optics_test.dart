import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/glass/yanji_glass_theme.dart';

void main() {
  testWidgets('edge magnification belongs to the moving indicator only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final tokens = YanjiGlassTheme.of(context);
            final moving = tokens.settings(YanjiGlassStrength.indicator);
            expect(moving.edgeMagnification, isTrue);
            expect(moving.copyWith(blur: 1).edgeMagnification, isTrue);
            expect(moving.copyWith(edgeMagnification: false), isNot(moving));
            for (final strength in [
              YanjiGlassStrength.surface,
              YanjiGlassStrength.control,
              YanjiGlassStrength.modal,
            ]) {
              expect(tokens.settings(strength).edgeMagnification, isFalse);
            }
            final resting = tokens.settings(
              YanjiGlassStrength.indicator,
              opticalActivity: 0,
            );
            expect(resting.thickness, 0);
            expect(resting.refractiveIndex, 1);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
