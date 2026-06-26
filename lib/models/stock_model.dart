/// Modèle représentant un stock de produits agricoles.
class Stock {
  final String id;
  final String produit;
  final double quantite;
  final String typeTraitement;
  final String entrepotId;
  final DateTime dateEntree;

  Stock({
    required this.id,
    required this.produit,
    required this.quantite,
    required this.typeTraitement,
    required this.entrepotId,
    required this.dateEntree,
  });

  /// Crée un objet Stock à partir des données de Supabase.
  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      produit: json['produit'],
      quantite: double.parse(json['quantite_kg'].toString()),
      typeTraitement: json['type_traitement'],
      entrepotId: json['entrepot_id'],
      dateEntree: DateTime.parse(json['date_entree']),
    );
  }

  /// Convertit l'objet en format JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produit': produit,
      'quantite_kg': quantite,
      'type_traitement': typeTraitement,
      'entrepot_id': entrepotId,
      'date_entree': dateEntree.toIso8601String(),
    };
  }
}