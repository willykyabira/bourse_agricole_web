// Fonctions CRUD Finance
import '../supabase_client.dart';

class FinanceService {
  final _supabase = BanSupabase.client;

  // 1. Récupérer toutes les transactions récentes
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

  // 2. Calculer le chiffre d'affaires total (Ventes)
  Future<double> getChiffreAffaireTotal() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('montant');
      
      double total = 0;
      for (var row in response) {
        total += (row['montant'] ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // 3. Récupérer les statistiques par produit (ex: Manioc vs Maïs)
  Future<List<Map<String, dynamic>>> getStatsProduits() async {
    try {
      // Cette requête groupe les ventes par nom de produit
      final response = await _supabase
          .from('transactions')
          .select('nom_produit, montant');
      
      return response;
    } catch (e) {
      return [];
    }
  }

  // 4. Valider une transaction (si vous avez un système de vérification)
  Future<void> validerPaiement(String transactionId) async {
    await _supabase
        .from('transactions')
        .update({'statut': 'valide'})
        .match({'id': transactionId});
  }
}