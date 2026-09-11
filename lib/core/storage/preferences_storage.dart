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

  static const String _keyRamRomCombinations = 'pref_ram_rom_combinations';

  static const List<String> defaultRamRomCombinations = [
    '2 GB / 32 GB',
    '3 GB / 32 GB',
    '3 GB / 64 GB',
    '4 GB / 64 GB',
    '4 GB / 128 GB',
    '6 GB / 64 GB',
    '6 GB / 128 GB',
    '8 GB / 128 GB',
    '8 GB / 256 GB',
    '12 GB / 256 GB',
    '12 GB / 512 GB',
    '16 GB / 512 GB',
    '16 GB / 1 TB',
  ];

  Future<List<String>> getRamRomCombinations() async {
    final prefs = await SharedPreferences.getInstance();
    final customList = prefs.getStringList(_keyRamRomCombinations);
    if (customList == null || customList.isEmpty) {
      return List.from(defaultRamRomCombinations);
    }
    final set = <String>{...defaultRamRomCombinations, ...customList};
    return set.toList();
  }

  Future<void> addRamRomCombination(String combination) async {
    final clean = combination.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRamRomCombinations();
    if (!existing.contains(clean)) {
      existing.add(clean);
      await prefs.setStringList(_keyRamRomCombinations, existing);
    }
  }
}
