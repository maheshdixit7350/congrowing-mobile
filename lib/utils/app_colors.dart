import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Brand Colors ────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryGradientStart = Color(0xFF7C3AED); // Violet
  static const Color primaryGradientEnd = Color(0xFF4F46E5); // Indigo dark
  static const Color accent = Color(0xFF06B6D4); // Cyan accent

  // ── Dark Mode Surfaces ──────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF080C18); // Deep navy black
  static const Color surfaceDark = Color(0xFF0F1629); // Card surface dark
  static const Color cardDark = Color(0xFF141B2D); // Slightly lighter card
  static const Color cardDarkElevated = Color(0xFF1A2340); // Elevated card
  static const Color dividerDark = Color(0xFF1E2A42);

  // ── Light Mode Surfaces ─────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardLightElevated = Color(0xFFF0F4FF);
  static const Color dividerLight = Color(0xFFE8ECF2);

  // ── Text Colors ─────────────────────────────────────────────────────────────
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textMainDark = Color(0xFFF1F5F9);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF475569);

  // ── Login Page Colors ───────────────────────────────────────────────────────
  static const Color loginPrimary = Color(0xFF0F2F44);
  static const Color loginPrimaryLight = Color(0xFF1A4A6B);
  static const Color loginSecondary = Color(0xFF3A7F41);
  static const Color loginSecondaryLight = Color(0xFF4DA656);
  static const Color loginAccent = Color(0xFFF4C430);

  // ── Semantic Colors ─────────────────────────────────────────────────────────
  static const Color green = Color(0xFF10B981);
  static const Color greenLight = Color(0xFF34D399);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color red = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFFCA5A5);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFF93C5FD);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);

  // ── Gradients ───────────────────────────────────────────────────────────────
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryGradientStart, primaryGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get heroGradient => const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get heroGradientDark => const LinearGradient(
        colors: [Color(0xFF1E1B4B), Color(0xFF3B0764), Color(0xFF0C4A6E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get successGradient => const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get dangerGradient => const LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get amberGradient => const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get cyanGradient => const LinearGradient(
        colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get loginGradient => const LinearGradient(
        colors: [loginPrimary, loginPrimaryLight, Color(0xFF2D6E4E), loginSecondary, loginPrimary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ── Glass Effect Colors ─────────────────────────────────────────────────────
  static Color glassLight(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color glassDark(double opacity) => const Color(0xFF1E2A42).withValues(alpha: opacity);
  static Color primaryGlass(double opacity) => primary.withValues(alpha: opacity);
}
