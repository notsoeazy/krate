import 'package:flutter/material.dart';

class KrateTheme {
  static const Color primary = Color(0xFF61AFEF);
  static const Color secondary = Color(0xFFC678DD);
  static const Color error = Color(0xFFE06C75);

  static const Color darkBackground = Color(0xFF1E2127);
  static const Color darkSurface = Color(0xFF282C34);
  static const Color darkSurfaceVariant = Color(0xFF2C313A);

  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onError = Colors.white;
  static const Color onSurface = Colors.white;
  static const Color onSurfaceVariant = Color(0xFFABB2BF);
  static const Color onSecondaryContainer = Color(0xFFE5C07B);
  static const Color errorContainer = Color(0xFF4B3133);
  static const Color onErrorContainer = Color(0xFFFFA7A7);
  static const Color secondaryContainer = Color(0xFF3E3549);

  static const Color outline = Color(0xFF3E4451);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,

      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,

      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,

      surface: darkBackground,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerLow: darkBackground,
      surfaceContainer: darkSurface,
      surfaceContainerHigh: darkSurfaceVariant,
      outline: outline,
    ),

    scaffoldBackgroundColor: darkBackground,

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: onSurfaceVariant),
      titleLarge: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: false,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontWeight: FontWeight.w600, 
            color: primary
          );
        } else {
          return const TextStyle(
            fontWeight: FontWeight.w500, 
            color: onSurfaceVariant
          );
        }
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary);
        }
        return const IconThemeData(color: onSurfaceVariant);
      }),
    ),

    tabBarTheme: const TabBarThemeData(
      dividerColor: outline,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: darkSurface,
    ),

    inputDecorationTheme: InputDecorationTheme(
      errorStyle: const TextStyle(color: error),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: error, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    cardTheme: const CardThemeData(
      color: darkSurface,
      margin: EdgeInsets.all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
