import 'package:flutter/material.dart';

/// Krate app theme system.
///
/// Currently ships with one dark theme variant. Additional variants (amoled,
/// light) can be added as new [ThemeVariant] values and handled in [of].
enum ThemeVariant { dark }

abstract class AppTheme {
  /// Returns the [ThemeData] for the requested [variant].
  static ThemeData of(ThemeVariant variant) {
    return switch (variant) {
      ThemeVariant.dark => dark,
    };
  }

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B61FF), // violet-purple accent
      brightness: Brightness.dark,
      surface: const Color(0xFF0F0F14),
      onSurface: const Color(0xFFE8E8F0),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F14),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1A1A24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F14),
      foregroundColor: Color(0xFFE8E8F0),
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF14141E),
      indicatorColor: const Color(0xFF7B61FF).withValues(alpha: 0.2),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w700,
        color: Color(0xFFE8E8F0),
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8E8F0),
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        color: Color(0xFFE8E8F0),
        fontSize: 16,
      ),
      bodyMedium: TextStyle(color: Color(0xFFAAAAAD), fontSize: 14),
      labelSmall: TextStyle(color: Color(0xFF888895), fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2A38),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Color(0xFF666675)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1A1A28),
      labelStyle: const TextStyle(color: Color(0xFFAAAAAD), fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF14141E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF7B61FF),
    ),
  );
}
