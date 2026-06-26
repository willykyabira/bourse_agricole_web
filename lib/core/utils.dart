import 'package:intl/intl.dart';

/// Classe contenant les fonctions utilitaires de l'application.
class BanUtils {
  /// Formate un montant en Franc Congolais par kilogramme.
  ///
  /// Exemple :
  /// 1200  ->  1 200 FC/Kg
  /// 15000 -> 15 000 FC/Kg
  static String formatPrix(double montant) {
    // Crée un format numérique en français (espace comme séparateur de milliers).
    final format = NumberFormat("#,###", "fr_FR");

    // Retourne le montant formaté suivi de l'unité.
    return "${format.format(montant)} FC/Kg";
  }
}
