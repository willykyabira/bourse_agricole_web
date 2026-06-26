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
      child: Padding(
        padding: const EdgeInsets.all(24),
        // Écoute en temps réel de la table 'produits' triée par date décroissante
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('produits')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Erreur : ${snapshot.error}"));
            }

            final data = snapshot.data ?? [];

            // Somme cumulative de toutes les quantités entrantes stockées
            final double stockTotal = data.fold(
              0.0,
              (sum, item) => sum + (double.tryParse(item['quantite'].toString()) ?? 0),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- BARRE DE TITRE & BOUTON D'ACTION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "HISTORIQUE DES ENTRÉES",
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _ouvrirFormulaire(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text("NOUVEAU PRODUIT"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20), // Vert officiel BAN
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- BANDEAU KPI : TOTAL DU STOCK ---
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Colors.white, size: 40),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stockTotal.toStringAsFixed(2),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Stock total enregistré",
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- TABLEAU DE DONNÉES (HISTORIQUE) ---
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 35,
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        headingRowHeight: 55,
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade300),
                          verticalInside: BorderSide(color: Colors.grey.shade300),
                        ),
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
                        headingTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text("DATE")),
                          DataColumn(label: Text("PRODUIT")),
                          DataColumn(label: Text("QUANTITÉ")),
                          DataColumn(label: Text("ACTIONS")),
                        ],
                        rows: List.generate(data.length, (i) {
                          final item = data[i];

                          return DataRow(
                            // Alternance de couleur de fond pour chaque ligne du tableau
                            color: WidgetStateProperty.resolveWith(
                              (states) => i.isEven ? Colors.white : Colors.grey.shade50,
                            ),
                            cells: [
                              // Cellule 1 : Date de création (Tronquée au format AAAA-MM-JJ)
                              DataCell(Text(item['created_at']?.toString().substring(0, 10) ?? '-')),
                              // Cellule 2 : Nom du produit
                              DataCell(Text(item['nom_produit'] ?? '-')),
                              // Cellule 3 : Quantité avec son badge d'unité stylisé
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    "${item['quantite']} ${item['unite_mesure'] ?? 'Kg'}",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ),
                              // Cellule 4 : Boutons d'actions (Détails, Édition, Suppression)
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: Colors.blue),
                                      onPressed: () => _voirDetails(context, item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      onPressed: () => _ouvrirFormulaire(context, item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _supprimer(context, item['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
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

  // Affiche le composant AjouterProduit à l'intérieur d'une boîte de dialogue Web modale
  void _ouvrirFormulaire(BuildContext context, Map<String, dynamic>? p) {
    showDialog(
      context: context,
      // ignore: deprecated_member_use
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: AjouterProduit(
              productToEdit: p,
              isDialog: true,
            ),
          ),
        );
      },
    );
  }

  // Ouvre une petite fiche descriptive contenant toutes les métadonnées de la ligne
  void _voirDetails(BuildContext context, Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p['nom_produit'] ?? "Détails"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row("Quantité", "${p['quantite']} ${p['unite_mesure'] ?? ''}"),
            _row("Catégorie", p['nom_categorie'] ?? '-'),
            _row("Date", p['created_at']?.toString().substring(0, 10) ?? '-'),
            _row("Client", p['nom_client'] ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          )
        ],
      ),
    );
  }

  // Petit constructeur de ligne d'information clé-valeur alignée
  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(a, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(b)),
        ],
      ),
    );
  }

  // Boîte de dialogue de confirmation avant suppression définitive dans Supabase
  Future<void> _supprimer(BuildContext context, dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer ce produit définitivement ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await Supabase.instance.client.from('produits').delete().eq('id', id);
    }
  }
}