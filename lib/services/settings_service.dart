import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static const _themeModeKey = 'krate_theme_mode';
  static const _themeSchemeIndexKey = 'krate_theme_scheme_index';

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeModeKey);
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index];
  }

  Future<void> setThemeSchemeIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeSchemeIndexKey, index);
  }

  Future<int> getThemeSchemeIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeSchemeIndexKey) ?? 0;
  }
}
