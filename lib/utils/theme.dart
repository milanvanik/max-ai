import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaxTheme {
  // Cloud Silver / Moonstone Palette
  static const Color background = Color(0xFF141416); // Deep charcoal
  static const Color surface = Color(0xFF222226); // Lighter charcoal for cards
  static const Color primary = Color(0xFFE2E8F0); // Cloud Silver
  static const Color secondary = Color(0xFF94A3B8); // Slate Gray
  static const Color accent = Color(0xFFBAE6FD); // Ice Blue accent

  static ThemeData get themeData {
    final baseTextTheme = ThemeData.dark().textTheme;
    
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        tertiary: accent,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: primary),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: primary),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: primary),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: primary),
        titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, color: primary),
        bodyLarge: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: primary, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20, 
          fontWeight: FontWeight.w600, 
          color: Colors.white
        ),
      ),
      useMaterial3: true,
    );
  }

  // Glassmorphism helper for bubbles and sheets
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1), 
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 15,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
}
