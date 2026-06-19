import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // --- GESTION DES UTILISATEURS ---
  Stream<List<Map<String, dynamic>>> fluxUtilisateurs() {
    return _supabase.from('profiles').stream(primaryKey: ['id']).order('nom_complet');
  }

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

  Future<void> supprimerUtilisateur(String id) async {
    await _supabase.from('profiles').delete().eq('id', id);
  }

  // --- GESTION DU STOCK (MANIOC) ---
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

  Stream<List<Map<String, dynamic>>> fluxStocks() {
    return _supabase
        .from('produits')
        .stream(primaryKey: ['id'])
        .order('date_entree', ascending: false);
  }

  // --- UTILITAIRES ---
  Future<List<Map<String, dynamic>>> fetchEntrepots() async {
    final res = await _supabase.from('entrepots').select('id, nom_entrepot');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, int>> fetchStats() async {
    final resUsers = await _supabase.from('profiles').select().count(CountOption.exact);
    final resEntrepots = await _supabase.from('entrepots').select().count(CountOption.exact);
    return {'users': resUsers.count, 'entrepots': resEntrepots.count};
  }
}