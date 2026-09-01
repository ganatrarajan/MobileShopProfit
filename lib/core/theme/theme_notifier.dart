import 'package:flutter/material.dart';
import '../storage/preferences_storage.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  final PreferencesStorage _prefs = PreferencesStorage();

  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  static final ThemeNotifier instance = ThemeNotifier();

  Future<void> _loadTheme() async {
    final modeStr = await _prefs.getThemeMode();
    // Default to light mode if not explicitly saved as dark
    value = _themeModeFromString(modeStr);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    await _prefs.saveThemeMode(_stringFromThemeMode(mode));
  }

  static ThemeMode _themeModeFromString(String str) {
    switch (str) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.light; // Prefer Light mode
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static String _stringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
      case ThemeMode.system:
      default:
        return 'light';
    }
  }
}
