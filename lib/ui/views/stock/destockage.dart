import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/ban_layout.dart';

class DestockageScreen extends StatelessWidget {
  const DestockageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "GESTION DES SORTIES / VENTES",
      activeRoute: '/gestion_sorties',
      child: Container(
        padding: const EdgeInsets.all(25),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          // On écoute la table 'sorties' en temps réel
          stream: supabase.from('sorties').stream(primaryKey: ['id']).order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? [];

            // --- CALCULS DES STATS RÉELLES ---
            double sortiesJour = 0;
            int commandesEnCours = 0;
            double chiffreAffaires = 0;
            DateTime aujourdhui = DateTime.now();

            for (var item in data) {
              double qte = double.tryParse(item['quantite'].toString()) ?? 0;
              double prix = double.tryParse(item['prix_total'].toString()) ?? 0;
              String statut = item['statut']?.toString().toLowerCase() ?? '';

              // 1. Sorties du jour
              DateTime dateSortie = DateTime.parse(item['created_at'].toString());
              if (dateSortie.year == aujourdhui.year && 
                  dateSortie.month == aujourdhui.month && 
                  dateSortie.day == aujourdhui.day) {
                sortiesJour += qte;
              }

              // 2. Commandes en cours (En attente / Traitement)
              if (statut == 'en attente' || statut == 'en cours') {
                commandesEnCours++;
              }

              // 3. Chiffre d'Affaires (Total des ventes livrées)
              chiffreAffaires += prix;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cartes de stats avec données réelles
                _buildQuickStats(sortiesJour, commandesEnCours, chiffreAffaires),
                
                const SizedBox(height: 35),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "HISTORIQUE DES LIVRAISONS", 
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18, 
                        color: const Color(0xFF4C6B8B)
                      )
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showSortieDialog(context),
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                      label: const Text("ENREGISTRER UNE SORTIE", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: data.isEmpty 
                    ? const Center(child: Text("Aucune sortie enregistrée."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                            columns: const [
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('PRODUIT')),
                              DataColumn(label: Text('DESTINATAIRE')),
                              DataColumn(label: Text('QUANTITÉ')),
                              DataColumn(label: Text('STATUT')),
                            ],
                            rows: data.map((item) => DataRow(
                              cells: [
                                DataCell(Text(item['created_at'].toString().substring(0, 10))),
                                DataCell(Text(item['nom_produit'] ?? '-')),
                                DataCell(Text(item['client'] ?? 'Vente comptant')),
                                DataCell(Text("${item['quantite']} ${item['unite']}")),
                                DataCell(_buildStatusChip(item['statut'] ?? 'Livré')),
                              ],
                            )).toList(),
                          ),
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

  Widget _buildQuickStats(double jour, int enCours, double ca) {
    return Row(
      children: [
        _statCard("Sorties du jour", "${jour.toStringAsFixed(1)} Kg", Icons.upload_rounded, Colors.orange),
        const SizedBox(width: 20),
        _statCard("Commandes en cours", "$enCours", Icons.pending_actions, Colors.blue),
        const SizedBox(width: 20),
        _statCard("Chiffre d'affaires", "${ca.toStringAsFixed(0)} \$", Icons.monetization_on, Colors.green),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status.toLowerCase() == 'livré' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showSortieDialog(BuildContext context) {
    // Note : Ici tu pourras intégrer ton formulaire de saisie réel
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enregistrer une nouvelle sortie"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: "Produit")),
            TextField(decoration: InputDecoration(labelText: "Quantité")),
            TextField(decoration: InputDecoration(labelText: "Client / Destination")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Valider la sortie")),
        ],
      ),
    );
  }
}