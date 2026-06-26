// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';
import 'package:fl_chart/fl_chart.dart';

class EcranStatistiques extends StatelessWidget {
  const EcranStatistiques({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "ANALYSE ET STATISTIQUES",
      activeRoute: '/stats_stock',
      // Écoute en temps réel des changements de la table 'produits'
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('produits').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final produits = snapshot.data!;
          double tonnageTotal = 0;
          double valeurTotale = 0;
          
          // Somme cumulative des quantités et valeurs monétaires globales
          for (var p in produits) {
            tonnageTotal += (p['quantite'] ?? 0).toDouble();
            valeurTotale += (p['prix_total'] ?? 0).toDouble();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Vue d'ensemble", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                
                // Cartes d'indicateurs de performance (KPI)
                Row(
                  children: [
                    _cardStat("STOCK TOTAL", "${tonnageTotal.toStringAsFixed(0)} Kg", Icons.inventory, Colors.blue),
                    const SizedBox(width: 20),
                    _cardStat("VALEUR ESTIMÉE", "${valeurTotale.toStringAsFixed(2)} \$", Icons.payments, Colors.green),
                    const SizedBox(width: 20),
                    _cardStat("PRODUITS ACTIFS", "${produits.length}", Icons.category, Colors.orange),
                  ],
                ),
                
                const SizedBox(height: 40),
                Text("Analyse visuelle : Répartition des valeurs", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                _buildChartSection(produits),
                
                const SizedBox(height: 40),
                Text("Détail des stocks par produit", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                _buildProductTable(produits),
              ],
            ),
          );
        },
      ),
    );
  }

  // Vérifie les clés possibles dans la Map pour extraire dynamiquement le nom du produit
  String _extraireNomProduit(Map<String, dynamic> p) {
    final keys = ['nom', 'libelle', 'designation', 'nom_produit', 'title', 'produit'];
    
    for (var key in keys) {
      if (p.containsKey(key) && p[key] != null) {
        return p[key].toString();
      }
    }
    return "Inconnu";
  }

  // Construit le graphique circulaire (camembert) représentant la valeur des stocks
  Widget _buildChartSection(List<Map<String, dynamic>> produits) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        // ignore: duplicate_ignore
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 60,
          // Transformation de chaque produit en une portion du graphique
          sections: produits.asMap().entries.map((entry) {
            int index = entry.key;
            var p = entry.value;
            double value = (p['prix_total'] ?? 0).toDouble();
            String nom = _extraireNomProduit(p);
            
            return PieChartSectionData(
              color: Colors.primaries[index % Colors.primaries.length],
              value: value,
              title: '$nom\n${value.toInt()}\$',
              radius: 80,
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Génère un tableau structuré listant les valeurs unitaires et globales
  Widget _buildProductTable(List<Map<String, dynamic>> produits) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // En-tête des colonnes du tableau
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("PRODUIT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text("QUANTITÉ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text("PRIX UNIT.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(child: Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
          ),
          // Lignes dynamiques remplies avec les données de Supabase
          ...produits.map((p) {
            String nomProduit = _extraireNomProduit(p);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(nomProduit, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Expanded(child: Text("${p['quantite'] ?? 0} Kg")),
                  Expanded(child: Text("${p['prix_unitaire'] ?? 0} \$")),
                  Expanded(child: Text("${p['prix_total'] ?? 0} \$", style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Constructeur d'une carte d'affichage statistique standard
  Widget _cardStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 15),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}