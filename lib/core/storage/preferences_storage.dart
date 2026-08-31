import 'package:shared_preferences/shared_preferences.dart';

class PreferencesStorage {
  static const String _keyThemeMode = 'pref_theme_mode'; // 'system', 'light', 'dark'
  static const String _keyLanguage = 'pref_language';    // 'en'
  static const String _keyCurrency = 'pref_currency';    // 'INR'
  static const String _keyAppLock = 'pref_app_lock_enabled';
  static const String _keyAppLockPin = 'pref_app_lock_pin';

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang);
  }

  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrency) ?? 'INR';
  }

  Future<void> saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
  }

  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAppLock) ?? false;
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLock, enabled);
  }

  Future<String?> getAppLockPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppLockPin);
  }

  Future<void> saveAppLockPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLockPin, pin);
  }
}
