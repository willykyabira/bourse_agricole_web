import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModifierProduit extends StatefulWidget {
  final Map<String, dynamic> product;
  const ModifierProduit({super.key, required this.product});

  @override
  State<ModifierProduit> createState() => _ModifierProduitState();
}

class _ModifierProduitState extends State<ModifierProduit> {
  late TextEditingController _nomController;
  late TextEditingController _quantiteController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Initialisation des contrôleurs avec les valeurs existantes du produit
    _nomController = TextEditingController(text: widget.product['nom_produit']?.toString() ?? '');
    _quantiteController = TextEditingController(text: widget.product['quantite']?.toString() ?? '0');
  }

  @override
  void dispose() {
    // Libération des ressources pour éviter les fuites de mémoire
    _nomController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }

  // Action de mise à jour des informations du produit dans Supabase
  Future<void> _updateProduct() async {
    final nom = _nomController.text.trim();
    final quantite = int.tryParse(_quantiteController.text) ?? 0;

    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le nom du produit ne peut pas être vide.")),
      );
      return;
    }

    try {
      await _supabase.from('produits').update({
        'nom_produit': nom,
        'quantite': quantite,
      }).eq('id', widget.product['id']);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la mise à jour : $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le Produit"), 
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Champ de saisie pour la désignation du produit
            TextField(
              controller: _nomController, 
              decoration: const InputDecoration(labelText: "Nom du produit"),
            ),
            const SizedBox(height: 10),
            // Champ de saisie numérique pour les quantités entrantes
            TextField(
              controller: _quantiteController, 
              decoration: const InputDecoration(labelText: "Quantité initiale"), 
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            // Bouton de validation
            ElevatedButton(
              onPressed: _updateProduct, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("METTRE À JOUR"),
            ),
          ],
        ),
      ),
    );
  }
}