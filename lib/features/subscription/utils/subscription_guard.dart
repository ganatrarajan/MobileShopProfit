import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/subscription_repository.dart';

class SubscriptionGuard {
  static final SubscriptionRepository _repository = SubscriptionRepository();

  /// Checks if subscription is active. If expired, shows renewal popup dialog and returns false.
  /// If active/valid, returns true.
  static Future<bool> checkAndGuard(BuildContext context, {String actionName = 'create new records'}) async {
    try {
      final res = await _repository.getStatus();
      if (res.success && res.data != null) {
        final dynamic raw = res.data;
        final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
            ? Map<String, dynamic>.from(raw['data'])
            : (raw is Map ? Map<String, dynamic>.from(raw) : {});

        final String status = data['status']?.toString() ?? 'active';
        final int daysRemaining = data['days_remaining'] is int
            ? data['days_remaining']
            : int.tryParse(data['days_remaining']?.toString() ?? '99') ?? 99;
        final bool isExpired = (data['is_expired'] == true || status == 'expired' || daysRemaining <= 0);

        if (isExpired) {
          if (context.mounted) {
            showSubscriptionExpiredDialog(context, actionName: actionName);
          }
          return false;
        }
      }
    } catch (_) {}
    return true;
  }

  static void showSubscriptionExpiredDialog(BuildContext context, {String actionName = 'create new records'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, size: 44, color: Colors.red.shade700),
              ),
              const SizedBox(height: 16),
              const Text(
                '⏰ Subscription Expired!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                'Your subscription plan has expired. Please renew your plan to $actionName in your shop.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    AppRoutes.navigatorKey.currentState?.pushNamed(AppRoutes.subscription);
                  },
                  icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                  label: const Text('Renew Plan Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
