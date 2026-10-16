import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/glass/liquid_glass_quality.dart';

void main() {
  test('HarmonyOS enables full glass only on a capable renderer', () {
    expect(
      YanjiGlassQuality.forRenderer(
        platform: 'ohos',
        shaderFiltersSupported: true,
      ),
      YanjiGlassQuality.high,
    );
    expect(
      YanjiGlassQuality.forRenderer(
        platform: 'ohos',
        shaderFiltersSupported: false,
      ),
      YanjiGlassQuality.reduced,
    );
  });

  test('web and explicit reduced mode take priority over platform support', () {
    for (final platform in ['ohos', 'iOS', 'macOS', 'android']) {
      expect(
        YanjiGlassQuality.forRenderer(
          platform: platform,
          shaderFiltersSupported: true,
          web: true,
          androidSdk: 36,
        ),
        YanjiGlassQuality.reduced,
      );
      expect(
        YanjiGlassQuality.forRenderer(
          platform: platform,
          shaderFiltersSupported: true,
          forceReduced: true,
          androidSdk: 36,
        ),
        YanjiGlassQuality.reduced,
      );
    }
  });

  test(
    'Android keeps its API boundary and Apple keeps its capability gate',
    () {
      for (final sdk in [null, 32, 33, 36]) {
        expect(
          YanjiGlassQuality.forRenderer(
            platform: 'android',
            shaderFiltersSupported: true,
            androidSdk: sdk,
          ),
          sdk != null && sdk >= 33
              ? YanjiGlassQuality.high
              : YanjiGlassQuality.reduced,
        );
      }
      for (final platform in ['iOS', 'macOS']) {
        expect(
          YanjiGlassQuality.forRenderer(
            platform: platform,
            shaderFiltersSupported: true,
          ),
          YanjiGlassQuality.high,
        );
        expect(
          YanjiGlassQuality.forRenderer(
            platform: platform,
            shaderFiltersSupported: false,
          ),
          YanjiGlassQuality.reduced,
        );
      }
      expect(
        YanjiGlassQuality.forRenderer(
          platform: 'unknown',
          shaderFiltersSupported: true,
        ),
        YanjiGlassQuality.reduced,
      );
    },
  );
}
