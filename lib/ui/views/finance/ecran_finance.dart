import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class EcranFinance extends StatelessWidget {
  const EcranFinance({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "Tableau de Bord Financier",
      activeRoute: '/finance',
      // Écoute en temps réel des modifications sur la table 'commandes'
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('commandes').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];

          // Variables de cumul pour le calcul des indicateurs financiers (KPIs)
          double totalGlobal = 0;
          double totalTransport = 0;
          double totalManutention = 0;
          double totalStockage = 0;
          double totalCommission = 0;
          double totalTva = 0;

          // Parcours et agrégation des montants reçus de Supabase (sécurité via cast num)
          for (final item in data) {
            totalGlobal += (item['prix_total'] as num?)?.toDouble() ?? 0;
            totalTransport +=
                (item['frais_transport'] as num?)?.toDouble() ?? 0;
            totalManutention +=
                (item['frais_manutention'] as num?)?.toDouble() ?? 0;
            totalStockage += (item['frais_stockage'] as num?)?.toDouble() ?? 0;
            totalCommission += (item['commission'] as num?)?.toDouble() ?? 0;
            totalTva += (item['montant_tva'] as num?)?.toDouble() ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildKpiGrid(
                  totalGlobal,
                  totalTransport,
                  totalManutention,
                  totalStockage,
                  totalCommission,
                  totalTva,
                ),
                const SizedBox(height: 30),
                _buildChartSection(data),
              ],
            ),
          );
        },
      ),
    );
  }

  // En-tête visuel avec dégradé bleu contenant le titre et la description de la page
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Finance Dashboard",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Analyse des revenus & charges en temps réel",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Grille responsive adaptant le nombre de colonnes (3, 2 ou 1) selon la taille de la fenêtre
  Widget _buildKpiGrid(
    double total,
    double transport,
    double manut,
    double stock,
    double comm,
    double tva,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
            ? 2
            : 1;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3,
          ),
          children: [
            _kpiCard("Total payé", total, Icons.receipt_long, Colors.green),
            _kpiCard("Transport", transport, Icons.local_shipping, Colors.blue),
            _kpiCard("Manutention", manut, Icons.handyman, Colors.indigo),
            _kpiCard("Stockage", stock, Icons.warehouse, Colors.teal),
            _kpiCard("Commissions", comm, Icons.percent, Colors.purple),
            _kpiCard("TVA", tva, Icons.payments, Colors.red),
          ],
        );
      },
    );
  }

  // Section graphique : Regroupe les prix totaux des commandes par mois (1 à 12)
  Widget _buildChartSection(List<Map<String, dynamic>> data) {
    final Map<int, double> monthlySales = {};

    // Extraction du mois depuis la date 'created_at' et cumul des ventes
    for (final item in data) {
      final rawDate = item['created_at'];
      if (rawDate != null) {
        final date = DateTime.tryParse(rawDate.toString());
        if (date != null) {
          final month = date.month;
          monthlySales[month] =
              (monthlySales[month] ?? 0) +
              ((item['prix_total'] as num?)?.toDouble() ?? 0);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chiffre d'affaires mensuel",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "M${value.toInt()}",
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                // Génération automatique des 12 barres correspondant aux 12 mois de l'année
                barGroups: List.generate(12, (index) {
                  final value = monthlySales[index + 1] ?? 0;
                  return BarChartGroupData(
                    x: index + 1,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.blue,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modèle de carte réutilisable pour afficher un indicateur clé (KPI) avec son icône
  Widget _kpiCard(String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "${value.toStringAsFixed(2)} \$",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
