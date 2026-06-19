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
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('commandes').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final data = snapshot.data ?? [];
          
          // 1. Calculs des KPIs (Restauration de votre logique originale)
          double totalPaye = 0;
          double totalEnAttente = 0;
          double totalTransport = 0;
          double totalManutention = 0;
          double totalStockage = 0;
          double totalCommission = 0;
          double totalTva = 0;

          for (var item in data) {
            final val = (item['prix_total'] as num?)?.toDouble() ?? 0.0;
            final statut = (item['statut'] as String? ?? '').toLowerCase();

            totalTransport += (item['frais_transport'] as num?)?.toDouble() ?? 0.0;
            totalManutention += (item['frais_manutention'] as num?)?.toDouble() ?? 0.0;
            totalStockage += (item['frais_stockage'] as num?)?.toDouble() ?? 0.0;
            totalCommission += (item['commission'] as num?)?.toDouble() ?? 0.0;
            totalTva += (item['montant_tva'] as num?)?.toDouble() ?? 0.0;

            if (statut == 'paye') {
              totalPaye += val;
            } else if (statut == 'proforma' || statut == 'reserve' || statut == 'en_cours_livraison') {
              totalEnAttente += val;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Vue d'ensemble", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 20),
                
                // Grid des indicateurs (KPIs)
                _buildKpiGrid(totalPaye, totalEnAttente, totalTransport, totalManutention, totalStockage, totalCommission, totalTva),
                
                const SizedBox(height: 32),
                
                // Graphique basé sur les données réelles
                _buildRevenueChart(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(double paye, double attente, double transport, double manut, double stock, double comm, double tva) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 2.2,
        children: [
          _kpiCard("Total Payé", paye, Icons.payments, Colors.green),
          _kpiCard("À Recevoir", attente, Icons.schedule, Colors.orange),
          _kpiCard("Transport", transport, Icons.local_shipping, Colors.blue),
          _kpiCard("Manutention", manut, Icons.handyman, Colors.indigo),
          _kpiCard("Stockage", stock, Icons.warehouse, Colors.teal),
          _kpiCard("Commissions", comm, Icons.percent, Colors.purple),
          _kpiCard("TVA Collectée", tva, Icons.receipt_long, Colors.red),
        ],
      );
    });
  }

  // --- Graphique avec données dynamiques ---
  Widget _buildRevenueChart(List<Map<String, dynamic>> data) {
    // Agrégation par mois
    Map<int, double> monthlySales = {};
    for (var item in data) {
      if (item['created_at'] != null) {
        DateTime date = DateTime.parse(item['created_at']);
        int month = date.month;
        monthlySales[month] = (monthlySales[month] ?? 0) + ((item['prix_total'] as num?)?.toDouble() ?? 0);
      }
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chiffre d'affaires par mois", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          SizedBox(height: 250, child: BarChart(
            BarChartData(
              barGroups: List.generate(12, (index) {
                return BarChartGroupData(
                  x: index + 1,
                  barRods: [BarChartRodData(toY: monthlySales[index + 1] ?? 0, color: Colors.blueAccent, width: 16, borderRadius: BorderRadius.circular(4))],
                );
              }),
              titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text("M${v.toInt()}")))),
            ),
          )),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
            Text("${value.toStringAsFixed(2)} \$", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ])),
        ],
      ),
    );
  }
}