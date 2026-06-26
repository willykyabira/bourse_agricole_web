import '../supabase_client.dart';

/// Service chargé de la gestion des opérations financières.
class FinanceService {
  final _supabase = BanSupabase.client;

  // ================= TRANSACTIONS =================

  /// Retourne la liste des transactions récentes.
  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des transactions : $e');
    }
  }

  /// Calcule le chiffre d'affaires total.
  Future<double> getChiffreAffaireTotal() async {
    try {
      final response = await _supabase.from('transactions').select('montant');

      double total = 0;

      for (final row in response) {
        total += (row['montant'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Retourne les statistiques des ventes par produit.
  Future<List<Map<String, dynamic>>> getStatsProduits() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('nom_produit, montant');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ================= PAIEMENTS =================

  /// Valide une transaction.
  Future<void> validerPaiement(String transactionId) async {
    await _supabase.from('transactions').update({'statut': 'valide'}).match({
      'id': transactionId,
    });
  }
}
