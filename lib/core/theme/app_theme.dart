import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1B2A3B),
      surfaceTint: Color(0xFF1B2A3B),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF2C4159),
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondary: Color(0xFF2E7D52),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE8F5EE),
      onSecondaryContainer: Color(0xFF0A3D24),
      tertiary: Color(0xFFBF8A30),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFFFF3DC),
      onTertiaryContainer: Color(0xFF3F2800),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFF8F9FA),
      onSurface: Color(0xFF111111),
      onSurfaceVariant: Color(0xFF666666),
      outline: Color(0xFFAAAAAA),
      outlineVariant: Color(0xFFE0E0E0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF1B2A3B),
      inversePrimary: Color(0xFF88D7A5),
      primaryFixed: Color(0xFFD0E4F7),
      onPrimaryFixed: Color(0xFF001D36),
      primaryFixedDim: Color(0xFFA8C8E8),
      onPrimaryFixedVariant: Color(0xFF1B2A3B),
      secondaryFixed: Color(0xFFB8E8CA),
      onSecondaryFixed: Color(0xFF00210F),
      secondaryFixedDim: Color(0xFF88D7A5),
      onSecondaryFixedVariant: Color(0xFF00522F),
      tertiaryFixed: Color(0xFFFFDDB0),
      onTertiaryFixed: Color(0xFF281800),
      tertiaryFixedDim: Color(0xFFF8BC5D),
      onTertiaryFixedVariant: Color(0xFF614000),
      surfaceDim: Color(0xFFE0E0E0),
      surfaceBright: Color(0xFFF8F9FA),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF5F5F5),
      surfaceContainer: Color(0xFFEEEEEE),
      surfaceContainerHigh: Color(0xFFE8E8E8),
      surfaceContainerHighest: Color(0xFFE0E0E0),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFA8C8E8),
      surfaceTint: Color(0xFFA8C8E8),
      onPrimary: Color(0xFF001D36),
      primaryContainer: Color(0xFF1B2A3B),
      onPrimaryContainer: Color(0xFFD0E4F7),
      secondary: Color(0xFF88D7A5),
      onSecondary: Color(0xFF00391F),
      secondaryContainer: Color(0xFF0A3D24),
      onSecondaryContainer: Color(0xFFB8E8CA),
      tertiary: Color(0xFFF8BC5D),
      onTertiary: Color(0xFF442C00),
      tertiaryContainer: Color(0xFF614000),
      onTertiaryContainer: Color(0xFFFFDDB0),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0F1923),
      onSurface: Color(0xFFE8EDF2),
      onSurfaceVariant: Color(0xFFB0B8C1),
      outline: Color(0xFF6B7680),
      outlineVariant: Color(0xFF2A3A4A),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE8EDF2),
      inversePrimary: Color(0xFF1B2A3B),
      primaryFixed: Color(0xFFD0E4F7),
      onPrimaryFixed: Color(0xFF001D36),
      primaryFixedDim: Color(0xFFA8C8E8),
      onPrimaryFixedVariant: Color(0xFF1B2A3B),
      secondaryFixed: Color(0xFFB8E8CA),
      onSecondaryFixed: Color(0xFF00210F),
      secondaryFixedDim: Color(0xFF88D7A5),
      onSecondaryFixedVariant: Color(0xFF00522F),
      tertiaryFixed: Color(0xFFFFDDB0),
      onTertiaryFixed: Color(0xFF281800),
      tertiaryFixedDim: Color(0xFFF8BC5D),
      onTertiaryFixedVariant: Color(0xFF614000),
      surfaceDim: Color(0xFF0F1923),
      surfaceBright: Color(0xFF1E2E3E),
      surfaceContainerLowest: Color(0xFF0A1220),
      surfaceContainerLow: Color(0xFF111D2A),
      surfaceContainer: Color(0xFF162030),
      surfaceContainerHigh: Color(0xFF1E2A38),
      surfaceContainerHighest: Color(0xFF253040),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainerLowest,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.outline,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return colorScheme.surfaceContainerHighest;
      }),
    ),
  );

  List<ExtendedColor> get extendedColors => [];
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