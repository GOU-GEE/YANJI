import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class YanJiSpacing {
  static const double xxs = 4,
      xs = 8,
      sm = 12,
      md = 16,
      lg = 24,
      xl = 32,
      xxl = 48;
}

abstract final class YanJiRadius {
  static const double small = 8, control = 12, card = 16, sheet = 24;
}

abstract final class YanJiElevation {
  static const double flat = 0, overlay = 2;
}

abstract final class YanJiLayout {
  static const double touch = 48, button = 52, input = 56;
  static const double content = 760, form = 560, sheet = 640;
  static const double railBreakpoint = 720, railMinHeight = 480;
  static const double icon = 24, quickIcon = 28;
  static const double compactWidth = 360;
  static bool stacked(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidth ||
      MediaQuery.textScalerOf(context).scale(16) >= 24;
}

abstract final class YanJiColors {
  static const primary = Color(0xFF355F4C);
  // Neutral reading surfaces; reserve the forest accent for meaningful states.
  static const canvasLight = Color(0xFFFAFAFC);
  static const canvasDark = Color(0xFF1C1C1E);
  static const transparent = Color(0x00000000);

  static Color canvas(Brightness b) =>
      b == Brightness.dark ? canvasDark : canvasLight;
  static Color warning(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFE8C17D) : const Color(0xFF805719);
  static Color information(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFA5CAE4) : const Color(0xFF345F7D);

  static ColorScheme scheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFF9CCEB0) : primary,
      onPrimary: dark ? const Color(0xFF153A27) : const Color(0xFFFFFFFF),
      primaryContainer: dark
          ? const Color(0xFF294636)
          : const Color(0xFFE0EDE1),
      onPrimaryContainer: dark
          ? const Color(0xFFC6E8CF)
          : const Color(0xFF254532),
      surface: dark ? const Color(0xFF242426) : const Color(0xFFFFFFFF),
      surfaceTint: transparent,
      surfaceDim: dark ? canvasDark : const Color(0xFFE9E9EE),
      surfaceBright: dark ? const Color(0xFF363638) : const Color(0xFFFFFFFF),
      surfaceContainerLowest: dark
          ? const Color(0xFF161618)
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: dark
          ? const Color(0xFF242426)
          : const Color(0xFFFFFFFF),
      surfaceContainer: dark
          ? const Color(0xFF28282A)
          : const Color(0xFFF5F5F7),
      surfaceContainerHigh: dark
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFEFEFF3),
      surfaceContainerHighest: dark
          ? const Color(0xFF363638)
          : const Color(0xFFE9E9EE),
      onSurface: dark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F),
      onSurfaceVariant: dark
          ? const Color(0xFFB5B5BD)
          : const Color(0xFF626269),
      outline: dark ? const Color(0xFF8E8E98) : const Color(0xFF797982),
      outlineVariant: dark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFA43D39),
    );
  }
}

abstract final class YanJiTypography {
  static const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 56,
      fontWeight: FontWeight.w400,
      height: 1.15,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
  );
}

ThemeData yanjiThemeFor(Brightness brightness) {
  final colors = YanJiColors.scheme(brightness);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(YanJiRadius.control),
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(YanJiRadius.control),
    borderSide: BorderSide(color: colors.outline),
  );
  final text = YanJiTypography.textTheme.apply(
    bodyColor: colors.onSurface,
    displayColor: colors.onSurface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    scaffoldBackgroundColor: YanJiColors.canvas(brightness),
    textTheme: text,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    iconTheme: IconThemeData(
      size: YanJiLayout.icon,
      color: colors.onSurfaceVariant,
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: yanjiSystemOverlayStyle(brightness),
      backgroundColor: YanJiColors.canvas(brightness),
      foregroundColor: colors.onSurface,
      surfaceTintColor: YanJiColors.transparent,
      elevation: YanJiElevation.flat,
      scrolledUnderElevation: YanJiElevation.flat,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      // Let text fields inherit the actual panel beneath them, including
      // translucent glass dialogs, instead of painting an opaque white fill.
      filled: false,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.all(YanJiSpacing.md),
      constraints: const BoxConstraints(minHeight: YanJiLayout.input),
      labelStyle: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(YanJiLayout.touch, YanJiLayout.button),
        padding: const EdgeInsets.symmetric(
          horizontal: YanJiSpacing.md,
          vertical: YanJiSpacing.sm,
        ),
        textStyle: text.labelLarge,
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(YanJiLayout.touch, YanJiLayout.button),
        padding: const EdgeInsets.symmetric(
          horizontal: YanJiSpacing.md,
          vertical: YanJiSpacing.sm,
        ),
        side: BorderSide(color: colors.outline),
        textStyle: text.labelLarge,
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(YanJiLayout.touch, YanJiLayout.touch),
        textStyle: text.labelLarge,
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(YanJiLayout.touch),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surface,
      selectedColor: colors.primaryContainer,
      checkmarkColor: colors.onPrimaryContainer,
      labelStyle: text.bodyMedium,
      side: BorderSide(color: colors.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YanJiRadius.small),
      ),
      padding: const EdgeInsets.all(YanJiSpacing.xs),
    ),
    dividerTheme: DividerThemeData(
      color: colors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: YanJiColors.transparent,
      elevation: YanJiElevation.overlay,
      constraints: const BoxConstraints(maxWidth: YanJiLayout.sheet),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(YanJiRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: YanJiColors.transparent,
      elevation: YanJiElevation.overlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YanJiRadius.sheet),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colors.surface,
      selectedLabelTextStyle: text.labelSmall?.copyWith(color: colors.primary),
      unselectedLabelTextStyle: text.labelSmall?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    ),
  );
}

abstract final class YanJiChartTokens {
  static const double trendHeight = 184, donutSize = 216, ringWidth = 24;
  static const double pointRadius = 4, selectedRadius = 6, lineWidth = 2;
  static const double areaOpacity = .10, curveTension = .2;
  static const forest = Color(0xFF355F4C),
      sage = Color(0xFF708F79),
      slate = Color(0xFF617C88),
      olive = Color(0xFF8B8D58),
      clay = Color(0xFFAC8065),
      fern = Color(0xFF4E827B);
  static const darkForest = Color(0xFF9CCEB0),
      darkSage = Color(0xFFB4C9AF),
      darkSlate = Color(0xFF9ABACB),
      darkOlive = Color(0xFFC6C794),
      darkClay = Color(0xFFD9B29A),
      darkFern = Color(0xFF8EC6BD);
  static Color subject(String id, Brightness brightness) {
    final palette = brightness == Brightness.dark
        ? [darkForest, darkSage, darkSlate, darkOlive, darkClay, darkFern]
        : [forest, sage, slate, olive, clay, fern];
    final hash = id.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return palette[hash % palette.length];
  }

  static Color subjectAt(int index, Brightness brightness) {
    final palette = brightness == Brightness.dark
        ? [darkForest, darkSage, darkSlate, darkOlive, darkClay, darkFern]
        : [forest, sage, slate, olive, clay, fern];
    return palette[index % palette.length];
  }
}

SystemUiOverlayStyle yanjiSystemOverlayStyle(Brightness brightness) =>
    (brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(
          statusBarColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: brightness,
        );

Widget yanjiSystemUiBuilder(BuildContext context, Widget? child) =>
    AnnotatedRegion<SystemUiOverlayStyle>(
      value: yanjiSystemOverlayStyle(Theme.of(context).brightness),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: child ?? const SizedBox.shrink(),
      ),
    );
