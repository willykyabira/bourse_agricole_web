import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class EcranRapportsFinance extends StatelessWidget {
  const EcranRapportsFinance({super.key});

  String getFriendlyStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paye': return 'Payé';
      case 'proforma': return 'Proforma';
      case 'reserve': return 'En Réserve';
      case 'en_cours_livraison': return 'En Livraison';
      case 'livre': return 'Livré';
      case 'dispute': return 'Litige';
      default: return status;
    }
  }

  String formatCurrency(double value) => "${value.toStringAsFixed(2)} \$";

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "Rapports Financiers",
      activeRoute: '/reports_finance',
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('commandes').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? [];

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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Vue d'ensemble", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _kpiCard("Total Payé", formatCurrency(totalPaye), Colors.green),
                    _kpiCard("À Recevoir", formatCurrency(totalEnAttente), Colors.orange),
                    _kpiCard("Transport", formatCurrency(totalTransport), Colors.blueGrey),
                    _kpiCard("Manutention", formatCurrency(totalManutention), Colors.blueGrey),
                    _kpiCard("Frais Stockage", formatCurrency(totalStockage), Colors.blueGrey),
                    _kpiCard("Commission", formatCurrency(totalCommission), Colors.purple),
                    _kpiCard("Total TVA", formatCurrency(totalTva), Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 40),
                Text("Détail des Transactions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _buildHistoryTable(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kpiCard(String title, String value, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildHistoryTable(List<Map<String, dynamic>> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Client")),
            DataColumn(label: Text("Transport")),
            DataColumn(label: Text("Manutention")),
            DataColumn(label: Text("Stockage")),
            DataColumn(label: Text("Commission")),
            DataColumn(label: Text("TVA (16%)")),
            DataColumn(label: Text("Total TTC")),
            DataColumn(label: Text("Statut")),
          ],
          rows: data.map((item) {
            final trans = (item['frais_transport'] as num?)?.toDouble() ?? 0.0;
            final manut = (item['frais_manutention'] as num?)?.toDouble() ?? 0.0;
            final stock = (item['frais_stockage'] as num?)?.toDouble() ?? 0.0;
            final comm = (item['commission'] as num?)?.toDouble() ?? 0.0;
            final tva = (item['montant_tva'] as num?)?.toDouble() ?? 0.0;
            final total = (item['prix_total'] as num?)?.toDouble() ?? 0.0;

            return DataRow(cells: [
              DataCell(Text(item['created_at']?.toString().split('T')[0] ?? "N/A")),
              DataCell(Text(item['nom_client'] ?? "Inconnu")),
              DataCell(Text("${trans.toStringAsFixed(2)} \$")),
              DataCell(Text("${manut.toStringAsFixed(2)} \$")),
              DataCell(Text(stock > 0 ? "${stock.toStringAsFixed(2)} \$" : "-")),
              DataCell(Text("${comm.toStringAsFixed(2)} \$")),
              DataCell(Text("${tva.toStringAsFixed(2)} \$")),
              DataCell(Text("${total.toStringAsFixed(2)} \$", style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Chip(label: Text(getFriendlyStatus(item['statut'] ?? "")))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}