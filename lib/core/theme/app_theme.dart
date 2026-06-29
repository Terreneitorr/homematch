import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff0a643b),
      surfaceTint: Color(0xff186c42),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff2e7d52),
      onPrimaryContainer: Color(0xffceffdb),
      secondary: Color(0xff386549),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff517e60),
      onSecondaryContainer: Color(0xfff6fff5),
      tertiary: Color(0xff805600),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffbf8a30),
      onTertiaryContainer: Color(0xff3f2800),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff7faf4),
      onSurface: Color(0xff181d19),
      onSurfaceVariant: Color(0xff3f4941),
      outline: Color(0xff6f7a71),
      outlineVariant: Color(0xffbfc9bf),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d312e),
      inversePrimary: Color(0xff88d7a5),
      primaryFixed: Color(0xffa4f4bf),
      onPrimaryFixed: Color(0xff002110),
      primaryFixedDim: Color(0xff88d7a5),
      onPrimaryFixedVariant: Color(0xff00522f),
      secondaryFixed: Color(0xffbceeca),
      onSecondaryFixed: Color(0xff00210f),
      secondaryFixedDim: Color(0xffa1d2af),
      onSecondaryFixedVariant: Color(0xff224f35),
      tertiaryFixed: Color(0xffffddb0),
      onTertiaryFixed: Color(0xff281800),
      tertiaryFixedDim: Color(0xfff8bc5d),
      onTertiaryFixedVariant: Color(0xff614000),
      surfaceDim: Color(0xffd7dbd5),
      surfaceBright: Color(0xfff7faf4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f5ee),
      surfaceContainer: Color(0xffebefe9),
      surfaceContainerHigh: Color(0xffe6e9e3),
      surfaceContainerHighest: Color(0xffe0e4dd),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003f23),
      surfaceTint: Color(0xff186c42),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff2c7b50),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff0f3e25),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff497759),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff4b3100),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff936405),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff7faf4),
      onSurface: Color(0xff0e120f),
      onSurfaceVariant: Color(0xff2f3831),
      outline: Color(0xff4b554d),
      outlineVariant: Color(0xff657067),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d312e),
      inversePrimary: Color(0xff88d7a5),
      primaryFixed: Color(0xff2c7b50),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff066239),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff497759),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff315e42),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff936405),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff734d00),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc4c8c2),
      surfaceBright: Color(0xfff7faf4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f5ee),
      surfaceContainer: Color(0xffe6e9e3),
      surfaceContainerHigh: Color(0xffdaded8),
      surfaceContainerHighest: Color(0xffcfd3cd),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00341c),
      surfaceTint: Color(0xff186c42),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff005531),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff02341c),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff255237),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff3e2800),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff644200),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff7faf4),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252e27),
      outlineVariant: Color(0xff424c44),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d312e),
      inversePrimary: Color(0xff88d7a5),
      primaryFixed: Color(0xff005531),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003b20),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff255237),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff0a3a22),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff644200),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff472e00),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb6bab4),
      surfaceBright: Color(0xfff7faf4),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeef2ec),
      surfaceContainer: Color(0xffe0e4dd),
      surfaceContainerHigh: Color(0xffd2d5d0),
      surfaceContainerHighest: Color(0xffc4c8c2),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff88d7a5),
      surfaceTint: Color(0xff88d7a5),
      onPrimary: Color(0xff00391f),
      primaryContainer: Color(0xff2e7d52),
      onPrimaryContainer: Color(0xffceffdb),
      secondary: Color(0xffa1d2af),
      onSecondary: Color(0xff073820),
      secondaryContainer: Color(0xff6c9b7b),
      onSecondaryContainer: Color(0xff001c0c),
      tertiary: Color(0xfff8bc5d),
      onTertiary: Color(0xff442c00),
      tertiaryContainer: Color(0xffbf8a30),
      onTertiaryContainer: Color(0xff3f2800),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff101411),
      onSurface: Color(0xffe0e4dd),
      onSurfaceVariant: Color(0xffbfc9bf),
      outline: Color(0xff89938a),
      outlineVariant: Color(0xff3f4941),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e4dd),
      inversePrimary: Color(0xff186c42),
      primaryFixed: Color(0xffa4f4bf),
      onPrimaryFixed: Color(0xff002110),
      primaryFixedDim: Color(0xff88d7a5),
      onPrimaryFixedVariant: Color(0xff00522f),
      secondaryFixed: Color(0xffbceeca),
      onSecondaryFixed: Color(0xff00210f),
      secondaryFixedDim: Color(0xffa1d2af),
      onSecondaryFixedVariant: Color(0xff224f35),
      tertiaryFixed: Color(0xffffddb0),
      onTertiaryFixed: Color(0xff281800),
      tertiaryFixedDim: Color(0xfff8bc5d),
      onTertiaryFixedVariant: Color(0xff614000),
      surfaceDim: Color(0xff101411),
      surfaceBright: Color(0xff363a36),
      surfaceContainerLowest: Color(0xff0b0f0c),
      surfaceContainerLow: Color(0xff181d19),
      surfaceContainer: Color(0xff1c211d),
      surfaceContainerHigh: Color(0xff272b27),
      surfaceContainerHighest: Color(0xff313632),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff9eeeb9),
      surfaceTint: Color(0xff88d7a5),
      onPrimary: Color(0xff002c17),
      primaryContainer: Color(0xff52a072),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffb6e8c4),
      onSecondary: Color(0xff002c17),
      secondaryContainer: Color(0xff6c9b7b),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffd69c),
      onTertiary: Color(0xff362200),
      tertiaryContainer: Color(0xffbf8a30),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff101411),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd5dfd4),
      outline: Color(0xffaab5ab),
      outlineVariant: Color(0xff89938a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e4dd),
      inversePrimary: Color(0xff005330),
      primaryFixed: Color(0xffa4f4bf),
      onPrimaryFixed: Color(0xff001508),
      primaryFixedDim: Color(0xff88d7a5),
      onPrimaryFixedVariant: Color(0xff003f23),
      secondaryFixed: Color(0xffbceeca),
      onSecondaryFixed: Color(0xff001508),
      secondaryFixedDim: Color(0xffa1d2af),
      onSecondaryFixedVariant: Color(0xff0f3e25),
      tertiaryFixed: Color(0xffffddb0),
      onTertiaryFixed: Color(0xff1b0f00),
      tertiaryFixedDim: Color(0xfff8bc5d),
      onTertiaryFixedVariant: Color(0xff4b3100),
      surfaceDim: Color(0xff101411),
      surfaceBright: Color(0xff414641),
      surfaceContainerLowest: Color(0xff050806),
      surfaceContainerLow: Color(0xff1a1f1b),
      surfaceContainer: Color(0xff252925),
      surfaceContainerHigh: Color(0xff2f3430),
      surfaceContainerHighest: Color(0xff3a3f3b),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbdffd2),
      surfaceTint: Color(0xff88d7a5),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff84d3a1),
      onPrimaryContainer: Color(0xff000f05),
      secondary: Color(0xffcafcd7),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xff9dceab),
      onSecondaryContainer: Color(0xff000f05),
      tertiary: Color(0xffffedd9),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xfff3b85a),
      onTertiaryContainer: Color(0xff130900),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff101411),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe8f3e8),
      outlineVariant: Color(0xffbbc5bb),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e4dd),
      inversePrimary: Color(0xff005330),
      primaryFixed: Color(0xffa4f4bf),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff88d7a5),
      onPrimaryFixedVariant: Color(0xff001508),
      secondaryFixed: Color(0xffbceeca),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffa1d2af),
      onSecondaryFixedVariant: Color(0xff001508),
      tertiaryFixed: Color(0xffffddb0),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff8bc5d),
      onTertiaryFixedVariant: Color(0xff1b0f00),
      surfaceDim: Color(0xff101411),
      surfaceBright: Color(0xff4d514d),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1c211d),
      surfaceContainer: Color(0xff2d312e),
      surfaceContainerHigh: Color(0xff383c38),
      surfaceContainerHighest: Color(0xff434844),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.background,
    canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
