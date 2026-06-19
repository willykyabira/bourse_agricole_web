// Formateurs de prix (FC/Kg)
import 'package:intl/intl.dart';

class BanUtils {
  // Formate un prix : 1200 -> 1 200 FC/Kg
  static String formatPrix(double montant) {
    final format = NumberFormat("#,###", "fr_FR");
    return "${format.format(montant)} FC/Kg";
  }
}