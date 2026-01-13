import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'house_colors.dart';

class AppTheme {
  // Main colors - Varsity + Neon aesthetic
  static const Color primaryDark = Color(0xFF0D1B2A);      // Deep navy
  static const Color primaryMid = Color(0xFF1B263B);       // Navy
  static const Color surfaceColor = Color(0xFF1E293B);     // Card surface
  static const Color accentNeon = Color(0xFF39FF14);       // Neon green
  static const Color accentGold = Color(0xFFFFD700);       // Gold
  static const Color accentCyan = Color(0xFF00F5FF);       // Cyan
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF22C55E);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      
      colorScheme: const ColorScheme.dark(
        primary: accentNeon,
        secondary: accentGold,
        tertiary: accentCyan,
        surface: surfaceColor,
        background: primaryDark,
        error: errorColor,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      
      // Typography - Varsity style headers
      textTheme: TextTheme(
        displayLarge: GoogleFonts.righteous(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.righteous(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.righteous(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.righteous(
          fontSize: 24,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryMid,
        selectedItemColor: accentNeon,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentNeon,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentNeon,
          side: const BorderSide(color: accentNeon, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryMid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentNeon, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      
      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentNeon,
        linearTrackColor: primaryMid,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),
    );
  }

  // Gradient backgrounds
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryMid],
  );

  static LinearGradient get neonGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentNeon, accentCyan],
  );

  static LinearGradient get goldGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGold, Color(0xFFFFAA00)],
  );

  // Box shadows for neon glow effect
  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.5}) => [
    BoxShadow(
      color: color.withOpacity(intensity * 0.5),
      blurRadius: 10,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: color.withOpacity(intensity * 0.3),
      blurRadius: 20,
      spreadRadius: 4,
    ),
  ];
}
