import 'package:flutter/material.dart';

// The theme is made with the help of this tool
// https://material-foundation.github.io/material-theme-builder/

// Text theme factory
TextTheme createTextTheme(
  BuildContext context,
  String bodyFontString, // passed as 'Inter' from main.dart
  String displayFontString,
) {
  final baseTextTheme = Theme.of(context).textTheme;
  return baseTextTheme.apply(
    fontFamily: bodyFontString,
    displayColor: Theme.of(context).colorScheme.onSurface,
    bodyColor: Theme.of(context).colorScheme.onSurface,
  );
}

// Material Theme
class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static List<
    ({String name, ColorScheme Function() light, ColorScheme Function() dark})
  >
  get schemes => [
    (name: 'Default', light: lightScheme, dark: darkScheme),
    (name: 'Midnight', light: midnightLightScheme, dark: midnightDarkScheme),
    (name: 'Forest', light: forestLightScheme, dark: forestDarkScheme),
    (name: 'Crimson', light: crimsonLightScheme, dark: crimsonDarkScheme),
    (name: 'Sunset', light: sunsetLightScheme, dark: sunsetDarkScheme),
    (name: 'Rose', light: roseLightScheme, dark: roseDarkScheme),
    (
      name: 'Monochrome',
      light: monochromeLightScheme,
      dark: monochromeDarkScheme,
    ),
  ];

  ThemeData light() => theme(lightScheme());
  ThemeData dark() => theme(darkScheme());

  // Default
  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff38608f),
      surfaceTint: Color(0xff38608f),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffd2e4ff),
      onPrimaryContainer: Color(0xff1c4975),
      secondary: Color(0xff535f70),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffd7e3f8),
      onSecondaryContainer: Color(0xff3c4858),
      tertiary: Color(0xff6c5778),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xfff4daff),
      onTertiaryContainer: Color(0xff533f5f),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff8f9ff),
      onSurface: Color(0xff191c20),
      onSurfaceVariant: Color(0xff43474e),
      outline: Color(0xff73777f),
      outlineVariant: Color(0xffc3c6cf),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2e3135),
      inversePrimary: Color(0xffa2c9fd),
      primaryFixed: Color(0xffd2e4ff),
      onPrimaryFixed: Color(0xff001c37),
      primaryFixedDim: Color(0xffa2c9fd),
      onPrimaryFixedVariant: Color(0xff1c4975),
      secondaryFixed: Color(0xffd7e3f8),
      onSecondaryFixed: Color(0xff101c2b),
      secondaryFixedDim: Color(0xffbbc7db),
      onSecondaryFixedVariant: Color(0xff3c4858),
      tertiaryFixed: Color(0xfff4daff),
      onTertiaryFixed: Color(0xff261431),
      tertiaryFixedDim: Color(0xffd8bde4),
      onTertiaryFixedVariant: Color(0xff533f5f),
      surfaceDim: Color(0xffd8dae0),
      surfaceBright: Color(0xfff8f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff2f3fa),
      surfaceContainer: Color(0xffeceef4),
      surfaceContainerHigh: Color(0xffe7e8ee),
      surfaceContainerHighest: Color(0xffe1e2e8),
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffa2c9fd),
      surfaceTint: Color(0xffa2c9fd),
      onPrimary: Color(0xff00325a),
      primaryContainer: Color(0xff1c4975),
      onPrimaryContainer: Color(0xffd2e4ff),
      secondary: Color(0xffbbc7db),
      onSecondary: Color(0xff253141),
      secondaryContainer: Color(0xff3c4858),
      onSecondaryContainer: Color(0xffd7e3f8),
      tertiary: Color(0xffd8bde4),
      onTertiary: Color(0xff3c2947),
      tertiaryContainer: Color(0xff533f5f),
      onTertiaryContainer: Color(0xfff4daff),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff111418),
      onSurface: Color(0xffe1e2e8),
      onSurfaceVariant: Color(0xffc3c6cf),
      outline: Color(0xff8d9199),
      outlineVariant: Color(0xff43474e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe1e2e8),
      inversePrimary: Color(0xff38608f),
      primaryFixed: Color(0xffd2e4ff),
      onPrimaryFixed: Color(0xff001c37),
      primaryFixedDim: Color(0xffa2c9fd),
      onPrimaryFixedVariant: Color(0xff1c4975),
      secondaryFixed: Color(0xffd7e3f8),
      onSecondaryFixed: Color(0xff101c2b),
      secondaryFixedDim: Color(0xffbbc7db),
      onSecondaryFixedVariant: Color(0xff3c4858),
      tertiaryFixed: Color(0xfff4daff),
      onTertiaryFixed: Color(0xff261431),
      tertiaryFixedDim: Color(0xffd8bde4),
      onTertiaryFixedVariant: Color(0xff533f5f),
      surfaceDim: Color(0xff111418),
      surfaceBright: Color(0xff37393e),
      surfaceContainerLowest: Color(0xff0b0e13),
      surfaceContainerLow: Color(0xff191c20),
      surfaceContainer: Color(0xff1d2024),
      surfaceContainerHigh: Color(0xff272a2f),
      surfaceContainerHighest: Color(0xff32353a),
    );
  }

  // Midnight (Indigo/Deep Blue)
  static ColorScheme midnightLightScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xff1a237e),
    brightness: Brightness.light,
  );
  static ColorScheme midnightDarkScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xff1a237e),
    brightness: Brightness.dark,
  );

  // Forest (Modern Green)
  static ColorScheme forestLightScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xff2e7d32),
    brightness: Brightness.light,
  );
  static ColorScheme forestDarkScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xff2e7d32),
    brightness: Brightness.dark,
  );

  // Crimson (Deep Red)
  static ColorScheme crimsonLightScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xffb71c1c),
    brightness: Brightness.light,
  );
  static ColorScheme crimsonDarkScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xffb71c1c),
    brightness: Brightness.dark,
  );

  // Sunset (Amber/Orange)
  static ColorScheme sunsetLightScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xffff8f00),
    brightness: Brightness.light,
  );
  static ColorScheme sunsetDarkScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xffff8f00),
    brightness: Brightness.dark,
  );

  // Rose (Pink/Rose)
  static ColorScheme roseLightScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xffe91e63),
    brightness: Brightness.light,
  );
  static ColorScheme roseDarkScheme() => ColorScheme.fromSeed(
    seedColor: const Color(0xffe91e63),
    brightness: Brightness.dark,
  );

  // Monochrome
  static ColorScheme monochromeLightScheme() => const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xff000000),
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xffe0e0e0),
    onPrimaryContainer: Color(0xff000000),
    secondary: Color(0xff424242),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xffeeeeee),
    onSecondaryContainer: Color(0xff212121),
    tertiary: Color(0xff616161),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xfff5f5f5),
    onTertiaryContainer: Color(0xff424242),
    error: Color(0xffb00020),
    onError: Color(0xffffffff),
    surface: Color(0xffffffff),
    onSurface: Color(0xff000000),
    onSurfaceVariant: Color(0xff757575),
    outline: Color(0xff9e9e9e),
    outlineVariant: Color(0xffbdbdbd),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xff212121),
    inversePrimary: Color(0xffffffff),
  );

  static ColorScheme monochromeDarkScheme() => const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xffffffff),
    onPrimary: Color(0xff000000),
    primaryContainer: Color(0xff424242),
    onPrimaryContainer: Color(0xffffffff),
    secondary: Color(0xffbdbdbd),
    onSecondary: Color(0xff000000),
    secondaryContainer: Color(0xff212121),
    onSecondaryContainer: Color(0xffeeeeee),
    tertiary: Color(0xff9e9e9e),
    onTertiary: Color(0xff000000),
    tertiaryContainer: Color(0xff333333),
    onTertiaryContainer: Color(0xffe0e0e0),
    error: Color(0xffcf6679),
    onError: Color(0xff000000),
    surface: Color(0xff121212),
    onSurface: Color(0xffffffff),
    onSurfaceVariant: Color(0xffbdbdbd),
    outline: Color(0xff757575),
    outlineVariant: Color(0xff424242),
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xffffffff),
    inversePrimary: Color(0xff000000),
  );

  // Base theme builder
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
      surfaceTintColor: colorScheme.surfaceTint,
      scrolledUnderElevation: 3.0,
      centerTitle: false,
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(1.0),
      backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerLow),
    ),
    searchViewTheme: SearchViewThemeData(
      elevation: 1.0,
      backgroundColor: colorScheme.surfaceContainerLow,
    ),
  );

  List<ExtendedColor> get extendedColors => [];
}

// Extended colour helpers (for custom seed colours added to the palette)
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
