import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warna sesuai color palette kamu
  static const Color color1 = Color(0xFFD08B0A); // coklat emas gelap
  static const Color color2 = Color(0xFFE9A512); // emas utama
  static const Color color3 = Color(0xFFFDC726); // kuning emas
  static const Color color4 = Color(0xFFFFF46C); // kuning terang
  static const Color color5 = Color(0xFFFEFFAF); // kuning sangat terang
  static const Color color6 = Color(0xFFFDFBD5); // krem/background

  // Alias yang dipakai di UI
  static const Color primaryColor = color2;
  static const Color primaryDark = color1;
  static const Color primaryLight = color4;
  static const Color backgroundColor = color5;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color dangerColor = Color(0xFFE53935);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: color3,
      ),
      textTheme: GoogleFonts.balooBhai2TextTheme().copyWith(
        displayLarge: GoogleFonts.arbutus(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.arbutus(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.bagelFatOne(
          fontSize: 20,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.alice(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.balooBhai2(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.balooBhai2(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.arbutus(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          textStyle: GoogleFonts.balooBhai2(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      useMaterial3: true,
    );
  }
}
