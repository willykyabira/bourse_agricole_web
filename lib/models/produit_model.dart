/// Modèle représentant un produit agricole.
class ProduitModel {
  final String? id;
  final String nom;
  final double prix;
  final String categorie;
  final String localisation;

  ProduitModel({
    this.id,
    required this.nom,
    required this.prix,
    required this.categorie,
    required this.localisation,
  });

  /// Crée un objet ProduitModel à partir des données de Supabase.
  factory ProduitModel.fromJson(Map<String, dynamic> json) {
    return ProduitModel(
      id: json['id'],
      nom: json['nom'],
      prix: json['prix'].toDouble(),
      categorie: json['categorie'],
      localisation: json['localisation'],
    );
  }

  /// Convertit l'objet en format JSON pour l'enregistrer dans Supabase.
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prix': prix,
      'categorie': categorie,
      'localisation': localisation,
    };
  }
}