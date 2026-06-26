import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Classe contenant le thème principal de l'application BAN.
class BanTheme {
  // ==========================
  // Couleurs de l'application
  // ==========================

  /// Couleur principale (vert agricole).
  static const Color banGreen = Color(0xFF1B5E20);

  /// Couleur secondaire (bleu).
  static const Color banBlue = Color(0xFF3F51B5);

  /// Couleur utilisée pour les éléments importants.
  static const Color banGold = Color(0xFFFBC02D);

  // ==========================
  // Thème clair
  // ==========================

  /// Thème utilisé par toute l'application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Couleur principale de l'application.
      primaryColor: banGreen,

      // Palette de couleurs utilisée par Material Design.
      colorScheme: ColorScheme.fromSeed(
        seedColor: banGreen,
        primary: banGreen,
        secondary: banBlue,
        tertiary: banGold,
      ),

      // Police utilisée dans toute l'application.
      textTheme: GoogleFonts.poppinsTextTheme(),
    );
  }
}
