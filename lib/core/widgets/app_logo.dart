import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppLogoSize { small, medium, large, splash }

class AppLogo extends StatelessWidget {
  final AppLogoSize size;
  final bool iconOnly;
  final bool showSubtitle;
  final bool isDarkBackground;
  final Color? customColor;

  const AppLogo({
    super.key,
    this.size = AppLogoSize.medium,
    this.iconOnly = false,
    this.showSubtitle = true,
    this.isDarkBackground = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final double iconDimension = switch (size) {
      AppLogoSize.small => 32.0,
      AppLogoSize.medium => 44.0,
      AppLogoSize.large => 68.0,
      AppLogoSize.splash => 96.0,
    };

    final double titleFontSize = switch (size) {
      AppLogoSize.small => 16.0,
      AppLogoSize.medium => 20.0,
      AppLogoSize.large => 26.0,
      AppLogoSize.splash => 34.0,
    };

    final double subtitleFontSize = switch (size) {
      AppLogoSize.small => 10.0,
      AppLogoSize.medium => 11.0,
      AppLogoSize.large => 13.0,
      AppLogoSize.splash => 14.0,
    };

    final textColor = customColor ?? (isDarkBackground ? Colors.white : AppColors.textPrimary);
    final subtitleColor = isDarkBackground ? Colors.white70 : AppColors.textSecondary;

    Widget logoIcon = Container(
      width: iconDimension,
      height: iconDimension,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(iconDimension * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: iconDimension * 0.3,
            offset: Offset(0, iconDimension * 0.12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Smartphone Outline
          Icon(
            Icons.phone_android_rounded,
            size: iconDimension * 0.58,
            color: Colors.white,
          ),
          // Profit Rupee Growth Badge overlay
          Positioned(
            right: iconDimension * 0.08,
            bottom: iconDimension * 0.08,
            child: Container(
              padding: EdgeInsets.all(iconDimension * 0.05),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: iconDimension * 0.04),
              ),
              child: Icon(
                Icons.trending_up_rounded,
                size: iconDimension * 0.28,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (iconOnly) {
      return logoIcon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoIcon,
        SizedBox(width: iconDimension * 0.3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontFamily: 'Roboto',
                ),
                children: [
                  TextSpan(
                    text: 'Mobile ',
                    style: TextStyle(color: textColor),
                  ),
                  TextSpan(
                    text: 'Profits',
                    style: TextStyle(
                      color: isDarkBackground ? Colors.amber : AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (showSubtitle && size != AppLogoSize.small) ...[
              const SizedBox(height: 2),
              Text(
                'Smart Shop Intelligence',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
