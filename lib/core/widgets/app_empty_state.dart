import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_no_internet_widget.dart';
import 'custom_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback? onAction;
  final bool isCompact;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.message,
    this.actionLabel,
    this.onActionPressed,
    this.onAction,
    this.isCompact = false,
  });

  String get effectiveDescription => description ?? message ?? '';
  VoidCallback? get effectiveOnAction => onActionPressed ?? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final fullText = '${title.toLowerCase()} ${effectiveDescription.toLowerCase()}';
    final isNetworkErr = icon == Icons.wifi_off_rounded ||
        icon == Icons.signal_wifi_connected_no_internet_4_rounded ||
        icon == Icons.error_outline ||
        fullText.contains('internet') ||
        fullText.contains('connect') ||
        fullText.contains('network') ||
        fullText.contains('socket') ||
        fullText.contains('unreachable') ||
        fullText.contains('unable to load');

    if (isNetworkErr) {
      return AppNoInternetWidget(
        title: title.contains('Unable') ? title : 'No Internet Connection',
        message: effectiveDescription.isNotEmpty ? effectiveDescription : 'Unable to connect to server. Please check your network connection and try again.',
        onRetry: effectiveOnAction,
        isCompact: isCompact,
      );
    }

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.textMuted.withOpacity(0.6)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              effectiveDescription,
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && effectiveOnAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: effectiveOnAction,
                icon: const Icon(Icons.add, size: 16),
                label: Text(actionLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              effectiveDescription,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && effectiveOnAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: CustomButton(
                  text: actionLabel!,
                  icon: Icons.add,
                  onPressed: effectiveOnAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
