import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class EcranRapportsFinance extends StatelessWidget {
  const EcranRapportsFinance({super.key});

  // Traduction des statuts techniques de la base de données en libellés lisibles
  String getFriendlyStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paye':
        return 'PAYÉ';
      case 'proforma':
        return 'PROFORMA';
      case 'reserve':
        return 'RÉSERVÉ';
      case 'en_cours_livraison':
        return 'LIVRAISON';
      case 'livre':
        return 'LIVRÉ';
      case 'dispute':
        return 'LITIGE';
      default:
        return status.toUpperCase();
    }
  }

  String formatCurrency(double value) => "${value.toStringAsFixed(2)} \$";

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "RAPPORTS FINANCIERS",
      activeRoute: '/reports_finance',
      // Stream en temps réel branché sur la table des commandes
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('commandes')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          // Initialisation des compteurs pour l'analyse globale des performances (KPIs)
          double totalPaye = 0;
          double totalEnAttente = 0;
          double totalTransport = 0;
          double totalManutention = 0;
          double totalStockage = 0;
          double totalCommission = 0;
          double totalTva = 0;

          // Cumul et ventilation des montants par poste de recette ou charge
          for (final item in data) {
            final val = (item['prix_total'] as num?)?.toDouble() ?? 0.0;
            final statut = (item['statut'] ?? '').toString().toLowerCase();

            totalTransport += (item['frais_transport'] as num?)?.toDouble() ?? 0.0;
            totalManutention += (item['frais_manutention'] as num?)?.toDouble() ?? 0.0;
            totalStockage += (item['frais_stockage'] as num?)?.toDouble() ?? 0.0;
            totalCommission += (item['commission'] as num?)?.toDouble() ?? 0.0;
            totalTva += (item['montant_tva'] as num?)?.toDouble() ?? 0.0;

            // Séparation logique des montants encaissés vs encours
            if (statut == 'paye') {
              totalPaye += val;
            } else {
              totalEnAttente += val;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Vue financière globale",
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Grille flexible (Wrap) alignant les cartes KPI d'analyse de caisse
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _kpiCard("Payé", totalPaye, Colors.green, Icons.check_circle),
                    _kpiCard("À recevoir", totalEnAttente, Colors.orange, Icons.pending),
                    _kpiCard("Transport", totalTransport, Colors.blue, Icons.local_shipping),
                    _kpiCard("Manutention", totalManutention, Colors.indigo, Icons.handyman),
                    _kpiCard("Stockage", totalStockage, Colors.teal, Icons.warehouse),
                    _kpiCard("Commission", totalCommission, Colors.purple, Icons.percent),
                    _kpiCard("TVA", totalTva, Colors.red, Icons.receipt),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  "Transactions détaillées",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                // Conteneur de la liste des transactions avec ombrage SaaS
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: data.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(child: Text("Aucune donnée")),
                        )
                      : Column(
                          children: data.map((item) {
                            return _FinanceRow(
                              item: item,
                              getFriendlyStatus: getFriendlyStatus,
                            );
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

  // Modèle de carte KPI (Card Style) avec bordure colorée transparente adaptative
  Widget _kpiCard(String title, double value, Color color, IconData icon) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(value),
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Ligne de données de transaction affichant la date, le client, le prix total et son badge
class _FinanceRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(String) getFriendlyStatus;

  const _FinanceRow({
    required this.item,
    required this.getFriendlyStatus,
  });

  @override
  Widget build(BuildContext context) {
    final total = (item['prix_total'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Extraction brute de la date (format AAAA-MM-JJ)
          Expanded(
            flex: 2,
            child: Text(
              item['created_at']?.toString().split('T')[0] ?? "--",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item['nom_client'] ?? "Inconnu",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "${total.toStringAsFixed(2)} \$",
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: _StatusBadge(
                status: getFriendlyStatus(item['statut'] ?? ""),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Badge d'état appliquant la charte de couleur verte (PAYÉ) ou orange (autres états)
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == "PAYÉ";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPaid ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
        ),
      ),
    );
  }
}