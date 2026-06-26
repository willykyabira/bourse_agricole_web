import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget affichant le logo officiel de la Bourse Agricole Numérique.
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
    const Color banGreen = Color(0xFF1B5E20);
    final Color mainColor = color ?? banGreen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(iconSize * 0.25),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: mainColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.eco_rounded,
            size: iconSize,
            color: mainColor,
          ),
        ),
        const SizedBox(height: 15),
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