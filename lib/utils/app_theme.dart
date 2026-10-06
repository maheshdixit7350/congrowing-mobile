import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surfaceLight,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardColor: AppColors.cardLight,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.textMainLight),
          displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textMainLight),
          headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textMainLight),
          headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textMainLight),
          titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textMainLight),
          titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textMainLight),
          bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, color: AppColors.textMainLight),
          bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, color: AppColors.textSecondaryLight),
          labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textTertiaryLight, letterSpacing: 0.5),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textMainLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.dividerLight, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardLightElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.dividerLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.dividerLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: AppColors.textTertiaryLight, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.cardLight,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textMainLight,
          contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondaryLight,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardLightElevated,
          selectedColor: AppColors.primaryGlass(0.15),
          side: BorderSide(color: AppColors.dividerLight),
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.dividerLight,
          thickness: 1,
          space: 0,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surfaceDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardColor: AppColors.cardDark,
        textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.textMainDark),
          displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textMainDark),
          headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textMainDark),
          headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textMainDark),
          titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textMainDark),
          titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textMainDark),
          bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, color: AppColors.textMainDark),
          bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, color: AppColors.textSecondaryDark),
          labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textTertiaryDark, letterSpacing: 0.5),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textMainDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.dividerDark, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardDarkElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.dividerDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.dividerDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: AppColors.textTertiaryDark, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.cardDarkElevated,
          contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundDark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondaryDark,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardDarkElevated,
          selectedColor: AppColors.primaryGlass(0.2),
          side: BorderSide(color: AppColors.dividerDark),
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMainDark),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.dividerDark,
          thickness: 1,
          space: 0,
        ),
      );
}
