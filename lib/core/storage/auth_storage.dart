import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyShop = 'auth_shop';

  static Map<String, dynamic>? _cachedUser;
  static Map<String, dynamic>? _cachedShop;

  static bool isOwnerUser(Map<String, dynamic>? user) {
    if (user == null) return true;
    final role = user['role']?.toString();
    return role == null || role.isEmpty || role == 'owner' || role == 'admin' || role == 'super_admin';
  }

  static bool hasModulePermission(Map<String, dynamic>? user, String module) {
    if (user == null) return true;
    if (isOwnerUser(user)) return true;
    final perms = user['permissions'];
    if (perms is Map) {
      final val = perms[module];
      return val == true || val == 1 || val.toString() == 'true';
    }
    return false;
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
    required Map<String, dynamic> shop,
  }) async {
    _cachedUser = user;
    _cachedShop = shop;
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
    if (_cachedUser != null) return _cachedUser;
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyUser);
    if (str != null) {
      _cachedUser = jsonDecode(str);
      return _cachedUser;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getShop() async {
    if (_cachedShop != null) return _cachedShop;
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyShop);
    if (str != null) {
      _cachedShop = jsonDecode(str);
      return _cachedShop;
    }
    return null;
  }

  Future<bool> isOwner() async {
    final user = await getUser();
    return isOwnerUser(user);
  }

  Future<bool> hasPermission(String module) async {
    final user = await getUser();
    return hasModulePermission(user, module);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    _cachedUser = null;
    _cachedShop = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyShop);
  }
}