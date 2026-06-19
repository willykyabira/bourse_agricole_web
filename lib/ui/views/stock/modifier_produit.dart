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
    _nomController = TextEditingController(text: widget.product['nom_produit']);
    _quantiteController = TextEditingController(text: widget.product['quantite'].toString());
    super.initState();
  }

  Future<void> _updateProduct() async {
    await _supabase.from('produits').update({
      'nom_produit': _nomController.text,
      'quantite': int.parse(_quantiteController.text),
    }).eq('id', widget.product['id']);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier le Produit"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nomController, decoration: const InputDecoration(labelText: "Nom")),
            TextField(controller: _quantiteController, decoration: const InputDecoration(labelText: "Quantité"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _updateProduct, child: const Text("METTRE À JOUR")),
          ],
        ),
      ),
    );
  }
}

