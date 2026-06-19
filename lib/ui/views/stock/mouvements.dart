import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/ban_layout.dart';
import 'ajouter_produit.dart';

class MouvementsScreen extends StatelessWidget {
  const MouvementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "GESTION DES ENTRÉES",
      activeRoute: '/mouvements',
      child: Container(
        padding: const EdgeInsets.all(25),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('produits').stream(primaryKey: ['id']).order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Erreur : ${snapshot.error}"));
            
            final data = snapshot.data ?? [];
            double stockTotal = data.fold(0.0, (sum, item) => sum + (double.tryParse(item['quantite'].toString()) ?? 0));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("HISTORIQUE DES ENTRÉES", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
                    ElevatedButton.icon(
                      onPressed: () => _ouvrirFormulaire(context, null),
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text("ENREGISTRER"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [DataColumn(label: Text('DATE')), DataColumn(label: Text('PRODUIT')), DataColumn(label: Text('QUANTITÉ')), DataColumn(label: Text('ACTIONS'))],
                        rows: data.map((item) => DataRow(cells: [
                          DataCell(Text(item['created_at']?.toString().substring(0, 10) ?? '-')),
                          DataCell(Text(item['nom_produit'] ?? '-')),
                          DataCell(Text("${item['quantite']} ${item['unite_mesure'] ?? 'Kg'}")),
                          DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _supprimer(context, item['id']))),
                        ])).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _ouvrirFormulaire(BuildContext context, Map<String, dynamic>? p) {
    showDialog(context: context, builder: (_) => Dialog(child: AjouterProduit(productToEdit: p, isDialog: true)));
  }
  
  Future<void> _supprimer(BuildContext context, dynamic id) async {
    await Supabase.instance.client.from('produits').delete().eq('id', id);
  }
}