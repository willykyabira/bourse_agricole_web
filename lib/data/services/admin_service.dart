import 'package:supabase_flutter/supabase_flutter.dart';

/// Service permettant à l'administrateur de gérer
/// les utilisateurs, les stocks et les statistiques.
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================= GESTION DES UTILISATEURS =================

  /// Retourne la liste des utilisateurs en temps réel.
  Stream<List<Map<String, dynamic>>> fluxUtilisateurs() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('nom_complet');
  }

  /// Crée un nouvel utilisateur.
  Future<void> creerAgent({
    required String email,
    required String password,
    required String nom,
    required String tel,
    required String role,
    String? entrepotId,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nom_complet': nom,
        'telephone': tel,
        'role': role,
        'entrepot_id': entrepotId,
      },
    );
  }

  /// Supprime un utilisateur.
  Future<void> supprimerUtilisateur(String id) async {
    await _supabase.from('profiles').delete().eq('id', id);
  }

  // ================= GESTION DU STOCK =================

  /// Ajoute un produit au stock.
  Future<void> ajouterStock({
    required double quantite,
    required String typeTraitement,
    required String entrepotId,
  }) async {
    await _supabase.from('produits').insert({
      'nom_produit': 'Manioc',
      'categorie': 'Transformés',
      'quantite': quantite,
      'type_traitement': typeTraitement,
      'entrepot_id': entrepotId,
      'date_entree': DateTime.now().toIso8601String(),
      'unite_mesure': 'Kg',
    });
  }

  /// Retourne les produits disponibles.
  Stream<List<Map<String, dynamic>>> fluxStocks() {
    return _supabase
        .from('produits')
        .stream(primaryKey: ['id'])
        .order('date_entree', ascending: false);
  }

  // ================= OUTILS =================

  /// Récupère la liste des entrepôts.
  Future<List<Map<String, dynamic>>> fetchEntrepots() async {
    final result = await _supabase.from('entrepots').select('id, nom_entrepot');

    return List<Map<String, dynamic>>.from(result);
  }

  /// Retourne les statistiques principales.
  Future<Map<String, int>> fetchStats() async {
    final users = await _supabase
        .from('profiles')
        .select()
        .count(CountOption.exact);

    final entrepots = await _supabase
        .from('entrepots')
        .select()
        .count(CountOption.exact);

    return {'users': users.count, 'entrepots': entrepots.count};
  }
}
