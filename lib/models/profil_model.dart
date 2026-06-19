// Modèle Profil
class ProfilModel {
  final String id;           // L'ID unique de l'utilisateur (UID Supabase)
  final String nom;          // Nom complet (ex: Willy Kyabira)
  final String email;        // Adresse email professionnelle
  final String role;         // Le rôle : 'admin', 'finance', ou 'stock'
  final String? telephone;   // Numéro de contact (optionnel)
  final DateTime? createdAt; // Date de création du compte

  ProfilModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.telephone,
    this.createdAt,
  });

  // Transforme les données venant de Supabase (JSON) en objet ProfilModel
  factory ProfilModel.fromJson(Map<String, dynamic> json) {
    return ProfilModel(
      id: json['id'],
      nom: json['nom'] ?? 'Utilisateur',
      email: json['email'] ?? '',
      role: json['role'] ?? 'invite', // Rôle par défaut si non défini
      telephone: json['telephone'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  // Prépare les données pour les envoyer ou les mettre à jour dans Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'role': role,
      'telephone': telephone,
    };
  }

  // Petite fonction pratique pour vérifier les permissions rapidement
  bool isAdmin() => role == 'admin';
  bool isFinance() => role == 'finance';
  bool isStock() => role == 'stock';
}