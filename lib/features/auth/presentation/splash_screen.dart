import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/storage/preferences_storage.dart';
import '../../../core/widgets/app_lock_verify_screen.dart';
import '../../../core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthStorage _authStorage = AuthStorage();
  final PreferencesStorage _prefs = PreferencesStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final bool loggedIn = await _authStorage.isLoggedIn();
    final user = await _authStorage.getUser();
    final shop = await _authStorage.getShop();

    if (mounted) {
      if (loggedIn) {
        final bool isLockEnabled = await _prefs.isAppLockEnabled();
        if (isLockEnabled) {
          final bool? unlocked = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AppLockVerifyScreen()),
          );
          if (unlocked != true) return;
        }

        final bool hasShop = (shop != null && shop['id'] != null) ||
            (user != null && (user['shop_id'] != null || user['shop'] != null));

        if (hasShop) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.shopSetup);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(
                size: AppLogoSize.splash,
                isDarkBackground: true,
                showSubtitle: true,
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}