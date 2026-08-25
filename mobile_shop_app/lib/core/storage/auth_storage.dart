import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyShop = 'auth_shop';

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
    required Map<String, dynamic> shop,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
    await prefs.setString(_keyShop, jsonEncode(shop));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyUser);
    if (str != null) {
      return jsonDecode(str);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getShop() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyShop);
    if (str != null) {
      return jsonDecode(str);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyShop);
  }
}