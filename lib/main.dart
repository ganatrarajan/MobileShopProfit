import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/storage/preferences_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/widgets/app_lock_verify_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MobileShopProfitApp());
}

class MobileShopProfitApp extends StatefulWidget {
  const MobileShopProfitApp({super.key});

  @override
  State<MobileShopProfitApp> createState() => _MobileShopProfitAppState();
}

class _MobileShopProfitAppState extends State<MobileShopProfitApp> with WidgetsBindingObserver {
  final PreferencesStorage _prefs = PreferencesStorage();
  bool _needsLockOnResume = false;
  bool _isLockShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _needsLockOnResume = true;
    } else if (state == AppLifecycleState.resumed) {
      if (_needsLockOnResume && !_isLockShowing) {
        _checkAndShowAppLock();
      }
    }
  }

  Future<void> _checkAndShowAppLock() async {
    _needsLockOnResume = false;
    final bool isLockEnabled = await _prefs.isAppLockEnabled();

    if (isLockEnabled && AppRoutes.navigatorKey.currentContext != null) {
      _isLockShowing = true;
      await AppRoutes.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const AppLockVerifyScreen()),
      );
      _isLockShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.instance,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Mobile Profits',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          navigatorKey: AppRoutes.navigatorKey,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}