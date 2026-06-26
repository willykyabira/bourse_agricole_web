/// Modèle représentant un utilisateur de l'application.
class ProfilModel {
  final String id;
  final String nom;
  final String email;
  final String role;
  final String? telephone;
  final DateTime? createdAt;

  ProfilModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.telephone,
    this.createdAt,
  });

  /// Crée un objet ProfilModel à partir des données de Supabase.
  factory ProfilModel.fromJson(Map<String, dynamic> json) {
    return ProfilModel(
      id: json['id'],
      nom: json['nom'] ?? 'Utilisateur',
      email: json['email'] ?? '',
      role: json['role'] ?? 'invite',
      telephone: json['telephone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  /// Convertit l'objet en format JSON pour l'enregistrer dans Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'role': role,
      'telephone': telephone,
    };
  }

  /// Vérifie si l'utilisateur est administrateur.
  bool isAdmin() => role == 'admin';

  /// Vérifie si l'utilisateur appartient au service financier.
  bool isFinance() => role == 'finance';

  /// Vérifie si l'utilisateur est gestionnaire de stock.
  bool isStock() => role == 'stock';
}