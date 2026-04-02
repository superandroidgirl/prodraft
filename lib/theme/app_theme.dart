import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color cardSurface = Color(0xFF1E1E2C);
  static const Color divider = Color(0xFF2A2A3E);

  // Brand
  static const Color primary = Color(0xFF00E676); // neon green
  static const Color primaryDark = Color(0xFF00B248);
  static const Color secondary = Color(0xFFFFD700); // gold
  static const Color accent = Color(0xFF00BFFF); // electric blue

  // Rarity colors
  static const Color rarityC = Color(0xFF9E9E9E); // grey
  static const Color rarityB = Color(0xFFCD7F32); // copper/bronze
  static const Color rarityA = Color(0xFFC0C0C0); // silver
  static const Color rarityS = Color(0xFFFFD700); // gold

  // Rank colors
  static const Color rankBronze = Color(0xFFCD7F32);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankPlatinum = Color(0xFF00BFFF);
  static const Color rankDiamond = Color(0xFF44CFCB);
  static const Color rankLegendary = Color(0xFFFF8C00);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textHint = Color(0xFF546E7A);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: Color(0xFFCF6679),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF141420),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.oswald(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.oswald(
          fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.oswald(
          fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.oswald(
          fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          letterSpacing: 1.0,
        ),
        headlineMedium: GoogleFonts.oswald(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14, color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.oswald(
          fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5,
        ),
      ),
    );
  }

  // Gradient backgrounds
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D0D1A), Color(0xFF121228)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient silverGradient = LinearGradient(
    colors: [Color(0xFFAFAFAF), Color(0xFFE8E8E8), Color(0xFFAFAFAF)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
