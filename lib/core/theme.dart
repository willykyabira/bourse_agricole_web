// Couleurs BAN et police Poppins
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BanTheme {
  static const Color banGreen = Color(0xFF1B5E20);
  static const Color banBlue = Color(0xFF3F51B5);
  static const Color banGold = Color(0xFFFBC02D);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: banGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: banGreen,
        primary: banGreen,
        secondary: banBlue,
        tertiary: banGold,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(), // On utilise Poppins partout
    );
  }
}