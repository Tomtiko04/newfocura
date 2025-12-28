import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Adaptive Colors
  static const Color restDeepPurple = Color(0xFF4A148C);
  static const Color restLightPurple = Color(0xFF7B1FA2);
  static const Color peakVibrantOrange = Color(0xFFFF6F00);
  static const Color peakWarmOrange = Color(0xFFFF8F00);
  static const Color adminCream = Color(0xFFFFF8E1);
  static const Color adminBeige = Color(0xFFF5E6D3);
  static const Color paperCream = Color(0xFFFDF6E3);
  static const Color paperParchment = Color(0xFFF4E4BC);
  static const Color primary = Color(0xFF5E35B1);
  static const Color secondary = Color(0xFFFF6F00);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: paperCream,
      textTheme: GoogleFonts.merriweatherTextTheme().copyWith(
        displayLarge: GoogleFonts.merriweather(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.brown[900],
        ),
        bodyLarge: GoogleFonts.merriweather(
          fontSize: 16,
          color: Colors.brown[800],
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paperParchment,
        elevation: 0,
        titleTextStyle: GoogleFonts.merriweather(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.brown[900],
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Get adaptive background color based on energy state
  static Color getAdaptiveBackground(String energyWindow) {
    switch (energyWindow) {
      case 'morning_peak':
        return peakVibrantOrange;
      case 'afternoon_admin':
        return adminCream;
      case 'evening_reflection':
        return restDeepPurple;
      default:
        return paperCream;
    }
  }
}

