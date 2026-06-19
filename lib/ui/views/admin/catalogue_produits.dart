import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';
import '../../views/stock/ajouter_produit.dart'; // Import de votre formulaire

class CatalogueProduits extends StatefulWidget {
  const CatalogueProduits({super.key});

  @override
  State<CatalogueProduits> createState() => _CatalogueProduitsState();
}

class _CatalogueProduitsState extends State<CatalogueProduits> {
  final _supabase = Supabase.instance.client;

  // Fonction pour ouvrir le formulaire que vous avez fourni
  void _ouvrirFormulaire({Map<String, dynamic>? produit}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AjouterProduit(
        productToEdit: produit,
        isDialog: true,
      ),
    );

    if (result == true) {
      setState(() {}); // Rafraîchir la liste après ajout/modification
    }
  }

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "CATALOGUE DES PRODUITS",
      activeRoute: '/products',
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            Expanded(child: _buildTableauProduits()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Inventaire global Ituri", style: TextStyle(color: Colors.grey.shade600)),
            Text("PRODUITS EN STOCK", 
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _ouvrirFormulaire(),
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: const Text("NOUVEAU PRODUIT", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTableauProduits() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('produits').stream(primaryKey: ['id']).order('date_recolte'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final produits = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("PRODUIT")),
                DataColumn(label: Text("CATÉGORIE")),
                DataColumn(label: Text("QUANTITÉ")),
                DataColumn(label: Text("PRIX TOTAL")),
                DataColumn(label: Text("PÉREMPTION")),
                DataColumn(label: Text("ACTIONS")),
              ],
              rows: produits.map((p) {
                final isExpired = DateTime.parse(p['date_peremption']).isBefore(DateTime.now());
                return DataRow(cells: [
                  DataCell(Text(p['nom_produit'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(p['categorie'])),
                  DataCell(Text("${p['quantite']} ${p['unite_mesure']}")),
                  DataCell(Text("${p['prix_total']} \$")),
                  DataCell(Text(
                    p['date_peremption'].toString().substring(0, 10),
                    style: TextStyle(color: isExpired ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                  )),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _ouvrirFormulaire(produit: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await _supabase.from('produits').delete().eq('id', p['id']);
                        },
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}