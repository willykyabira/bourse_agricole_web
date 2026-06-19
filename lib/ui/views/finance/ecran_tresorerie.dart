import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class EcranTresorerie extends StatelessWidget {
  const EcranTresorerie({super.key});

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "Tableau de Bord Trésorerie",
      activeRoute: '/tresorerie',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client.from('tresorerie').select('*'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(child: Text("Aucune opération enregistrée."));
          }

          final data = snapshot.data!;
          // Calcul des indicateurs
          double entrees = 0;
          double sorties = 0;
          for (var item in data) {
            double val = double.tryParse(item['montant'].toString()) ?? 0;
            if (item['type'] == 'entree') entrees += val;
            else sorties += val;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION KPI (Les cartes de résumé) ---
                Row(
                  children: [
                    _kpiCard("SOLDE ACTUEL", (entrees - sorties).toStringAsFixed(2), Colors.blue, Icons.account_balance),
                    const SizedBox(width: 20),
                    _kpiCard("TOTAL ENTRÉES", entrees.toStringAsFixed(2), Colors.green, Icons.arrow_downward),
                    const SizedBox(width: 20),
                    _kpiCard("TOTAL SORTIES", sorties.toStringAsFixed(2), Colors.red, Icons.arrow_upward),
                  ],
                ),
                const SizedBox(height: 30),

                // --- SECTION ACTIONS & TITRE ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Opérations récentes", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () { /* TODO: Ouvrir modal ajout */ },
                      icon: const Icon(Icons.add),
                      label: const Text("Nouvelle Opération"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // --- SECTION TABLEAU ---
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text("Libellé", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Montant", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: data.map((item) {
                      bool isEntree = item['type'] == 'entree';
                      return DataRow(cells: [
                        DataCell(Text(item['libelle'] ?? "-")),
                        DataCell(Text(item['created_at']?.toString().substring(0, 10) ?? "-")),
                        DataCell(Chip(
                          label: Text(isEntree ? "Entrée" : "Sortie", style: TextStyle(color: isEntree ? Colors.green : Colors.red, fontSize: 12)),
                          backgroundColor: (isEntree ? Colors.green : Colors.red).withOpacity(0.1),
                        )),
                        DataCell(Text(
                          "${isEntree ? '+' : '-'} ${item['montant']} FC",
                          style: TextStyle(color: isEntree ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget de carte KPI réutilisable
  Widget _kpiCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}