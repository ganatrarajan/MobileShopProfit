import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette - Rich Purple & Deep Black SaaS
  static const Color primary = Color(0xFF6D28D9);      // Deep Purple 700
  static const Color primaryDark = Color(0xFF5B21B6);  // Deep Purple 800
  static const Color primaryLight = Color(0xFF8B5CF6); // Purple 500
  static const Color secondary = Color(0xFF4C1D95);    // Dark Violet 900

  // Signal Accents
  static const Color accent = Color(0xFF10B981);       // Emerald Profit 500
  static const Color accentLight = Color(0xFFD1FAE5);  // Emerald 100
  static const Color warning = Color(0xFFF59E0B);      // Amber 500
  static const Color error = Color(0xFFEF4444);        // Red 500
  static const Color errorLight = Color(0xFFFEE2E2);   // Red 100
  static const Color success = Color(0xFF10B981);      // Emerald 500

  // Light Mode Surfaces & Crisp Backgrounds
  static const Color background = Color(0xFFF8FAFC);   // Soft Slate 50
  static const Color surface = Color(0xFFFFFFFF);      // Pure White Card Surface
  static const Color border = Color(0xFFE2E8F0);        // Slate 200 Border
  static const Color inputFill = Color(0xFFF1F5F9);     // Slate 100 Fill

  // High-Contrast Crisp Typography
  static const Color textPrimary = Color(0xFF0F172A);   // Deep Black / Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF64748B);     // Slate 500

  // Dark Mode Surfaces (Fallback)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Gradient definitions for header banners and buttons
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}