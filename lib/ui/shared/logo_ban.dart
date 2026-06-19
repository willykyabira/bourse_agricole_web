// Widget Logo BAN
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoBAN extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color? color;

  const LogoBAN({
    super.key, 
    this.iconSize = 60, 
    this.fontSize = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // On récupère le vert officiel de la BAN
    const Color banGreen = Color(0xFF1B5E20);
    final Color mainColor = color ?? banGreen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Le conteneur du logo (Cercle avec icône)
        Container(
          padding: EdgeInsets.all(iconSize * 0.25),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: mainColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.eco_rounded, // L'icône de la bourse agricole
            size: iconSize,
            color: mainColor,
          ),
        ),
        
        const SizedBox(height: 15),
        
        // Nom de l'application (BAN ITURI)
        Text(
          "BAN ITURI",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: mainColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        
        // Sous-titre
        Text(
          "Bourse Agricole Numérique",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: fontSize * 0.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}