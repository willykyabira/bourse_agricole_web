import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import '../../widgets/ban_layout.dart';

class EcranRapports extends StatelessWidget {
  const EcranRapports({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "CENTRE DE RAPPORTS DYNAMIQUES",
      activeRoute: '/reports_stock',
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: StreamBuilder(
          stream: supabase.from('produits').stream(primaryKey: ['id']),
          builder: (context, snapshotEntrees) {
            return StreamBuilder(
              stream: supabase.from('sorties').stream(primaryKey: ['id']),
              builder: (context, snapshotSorties) {
                if (!snapshotEntrees.hasData || !snapshotSorties.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // --- LOGIQUE DE CALCUL ---
                double valeurTotaleStock = 0;
                double volumeSortiesMois = 0;
                int alertesStockFaible = 0;
                Map<String, double> stocksParProduit = {};

                for (var row in snapshotEntrees.data!) {
                  double qte = double.tryParse(row['quantite'].toString()) ?? 0.0;
                  double prix = double.tryParse(row['prix_total'].toString()) ?? 0.0;
                  valeurTotaleStock += prix;
                  String nom = row['nom_produit'];
                  stocksParProduit[nom] = (stocksParProduit[nom] ?? 0) + qte;
                }

                for (var row in snapshotSorties.data!) {
                  double qteSortie = double.tryParse(row['quantite'].toString()) ?? 0.0;
                  volumeSortiesMois += qteSortie;
                  String nom = row['nom_produit'];
                  if (stocksParProduit.containsKey(nom)) {
                    stocksParProduit[nom] = stocksParProduit[nom]! - qteSortie;
                  }
                }

                stocksParProduit.forEach((nom, qte) {
                  if (qte < 10) alertesStockFaible++;
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("RAPPORT DE SYNTHÈSE (TEMPS RÉEL)", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    const SizedBox(height: 25),
                    
                    _buildFeaturedReport(
                      context,
                      title: "Rapport de Valorisation BAN",
                      description: "Valeur actuelle du stock : ${valeurTotaleStock.toStringAsFixed(2)} \$ USD. Volume total des sorties : ${volumeSortiesMois.toStringAsFixed(1)} Kg. $alertesStockFaible produit(s) en rupture critique.",
                      icon: Icons.assignment_turned_in_outlined,
                      color: const Color(0xFF1B5E20),
                      onDownload: () async {
                        final pdf = pw.Document();
                        pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text("Rapport BAN: $valeurTotaleStock \$"))));
                        await Printing.layoutPdf(onLayout: (format) => pdf.save());
                      }
                    ),
                    
                    const SizedBox(height: 40),
                    Text("AUTRES DOCUMENTS COMPTABLES", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const Divider(),
                    
                    Expanded(
                      child: ListView(
                        children: [
                          _buildReportItem("Registre des Mouvements (Journal)", "CSV", Icons.history, () async {
                            List<List<dynamic>> rows = [["Produit", "Quantité"], ...stocksParProduit.entries.map((e) => [e.key, e.value])];
                            String csv = const ListToCsvConverter().convert(rows);
                            final bytes = utf8.encode(csv);
                            final blob = html.Blob([bytes]);
                            final url = html.Url.createObjectUrlFromBlob(blob);
                            html.AnchorElement(href: url)..setAttribute("download", "mouvements.csv")..click();
                          }),
                          _buildReportItem("État de Valorisation par Entrepôt", "PDF", Icons.account_balance_wallet_outlined, () {}),
                          _buildReportItem("Analyse des Pertes et Écarts", "PDF", Icons.trending_down, () {}),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedReport(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required VoidCallback onDownload}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3), width: 2), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 45)),
          const SizedBox(width: 25),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(description, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5))])),
          ElevatedButton.icon(
            onPressed: onDownload, 
            icon: const Icon(Icons.download_for_offline, color: Colors.white),
            label: const Text("TÉLÉCHARGER LE RAPPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(String title, String format, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("Format de sortie : $format"),
        trailing: IconButton(onPressed: onTap, icon: const Icon(Icons.print_outlined, color: Color(0xFF1A237E))),
      ),
    );
  }
}