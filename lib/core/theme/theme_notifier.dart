import 'package:flutter/material.dart';
import '../storage/preferences_storage.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  final PreferencesStorage _prefs = PreferencesStorage();

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static final ThemeNotifier instance = ThemeNotifier();

  Future<void> _loadTheme() async {
    final modeStr = await _prefs.getThemeMode();
    value = _themeModeFromString(modeStr);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    await _prefs.saveThemeMode(_stringFromThemeMode(mode));
  }

  static ThemeMode _themeModeFromString(String str) {
    switch (str) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _stringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}
