import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warna asas untuk latar belakang gelap (fluid gradient background)
  static const Color bgDark = Color(0xFF070B12);
  static const Color bgGradientStart = Color(0xFF0F1626);
  static const Color bgGradientEnd = Color(0xFF05080F);
  
  // Warna neon untuk glow effect & hiasan latar belakang
  static const Color neonPurple = Color(0xFF6C5DD3);
  static const Color neonBlue = Color(0xFF2DD4A8);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.plusJakartaSans(color: const Color(0xFFF8FAFC)),
        bodyMedium: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
      ),
      // Konfigurasi warna primer aplikasi
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: neonPurple,
        surface: Color(0xFF0F1626),
      ),
    );
  }
}