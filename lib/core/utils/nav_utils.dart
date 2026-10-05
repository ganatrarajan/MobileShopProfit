import 'package:flutter/material.dart';

class NavUtils {
  static DateTime _lastNavTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Safely pushes a named route with a 400ms debounce to prevent double-tap duplicate screens
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    final now = DateTime.now();
    if (now.difference(_lastNavTime).inMilliseconds < 400) {
      return null;
    }
    _lastNavTime = now;
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }
}