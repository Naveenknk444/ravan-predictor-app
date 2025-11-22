import 'package:flutter/material.dart';

/// App color palette - matches mockup designs exactly
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFD4AF37);        // Gold
  static const Color primaryDark = Color(0xFFAA8C2C);    // Dark gold
  static const Color primaryLight = Color(0xFFF4D03F);   // Light gold

  // Background Colors
  static const Color background = Color(0xFF0D0D0D);     // Main background
  static const Color surface = Color(0xFF111111);        // Card/surface background
  static const Color surfaceLight = Color(0xFF1A1A1A);   // Slightly lighter surface
  static const Color surfaceDark = Color(0xFF000000);    // Black

  // Border Colors
  static const Color border = Color(0xFF333333);         // Default border
  static const Color borderLight = Color(0xFF444444);    // Lighter border

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);    // White text
  static const Color textSecondary = Color(0xFF888888);  // Grey text
  static const Color textTertiary = Color(0xFF666666);   // Darker grey text
  static const Color textGold = Color(0xFFD4AF37);       // Gold text

  // Status Colors
  static const Color success = Color(0xFF22C55E);        // Green
  static const Color error = Color(0xFFEF4444);          // Red
  static const Color warning = Color(0xFFF59E0B);        // Orange/Amber
  static const Color info = Color(0xFF3B82F6);           // Blue

  // Accent Colors
  static const Color purple = Color(0xFF8B5CF6);         // Purple (for effects)

  // Overlay Colors
  static const Color overlay = Color(0x80000000);        // 50% black overlay
  static const Color overlayLight = Color(0x40000000);   // 25% black overlay

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFAA8C2C)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x26D4AF37),  // 15% gold
      Color(0x1AAA8C2C),  // 10% dark gold
    ],
  );

  // Status with opacity for backgrounds
  static Color successBg = success.withOpacity(0.15);
  static Color errorBg = error.withOpacity(0.15);
  static Color warningBg = warning.withOpacity(0.15);
  static Color infoBg = info.withOpacity(0.15);
  static Color primaryBg = primary.withOpacity(0.15);
}
