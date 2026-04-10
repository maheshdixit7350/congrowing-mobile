import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryGradientStart = Color(0xFF7C3AED); // Violet
  static const Color primaryGradientEnd = Color(0xFF4F46E5); // Indigo dark

  // Background colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);

  // Card colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color textMainLight = Color(0xFF111827);
  static const Color textMainDark = Color(0xFFF3F4F6);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Login page colors
  static const Color loginPrimary = Color(0xFF0F2F44);
  static const Color loginPrimaryLight = Color(0xFF1A4A6B);
  static const Color loginSecondary = Color(0xFF3A7F41);
  static const Color loginSecondaryLight = Color(0xFF4DA656);
  static const Color loginAccent = Color(0xFFF4C430);

  // Utility shades
  static const Color green = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryGradientStart, primaryGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get loginGradient => const LinearGradient(
        colors: [loginPrimary, loginPrimaryLight, Color(0xFF2D6E4E), loginSecondary, loginPrimary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
