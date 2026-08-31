import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthStorage _authStorage = AuthStorage();

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
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mobile Shop Profit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Shop Management & Profit SaaS',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}