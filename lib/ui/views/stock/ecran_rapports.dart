import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
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
      title: "CENTRE DE RAPPORTS",
      activeRoute: '/reports_stock',
      child: Padding(
        padding: const EdgeInsets.all(24),
        // On écoute d'abord le flux de la table 'produits'
        child: StreamBuilder(
          stream: supabase.from('produits').stream(primaryKey: ['id']),
          builder: (context, snapshotEntrees) {
            // On écoute ensuite le flux de la table 'sorties' (imbrication pour combiner les données)
            return StreamBuilder(
              stream: supabase.from('sorties').stream(primaryKey: ['id']),
              builder: (context, snapshotSorties) {
                // Attente du chargement des deux tables
                if (!snapshotEntrees.hasData || !snapshotSorties.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final produits = snapshotEntrees.data!;
                final sorties = snapshotSorties.data!;

                // Initialisation des compteurs pour nos statistiques globales
                double valeurStock = 0;
                double volumeSorties = 0;
                int alertes = 0;

                // Dictionnaire (Map) pour stocker le niveau réel de stock par produit
                final Map<String, double> stockMap = {};

                // Calcul du stock initial basé sur les entrées de marchandises
                for (final p in produits) {
                  final qte = (p['quantite'] ?? 0).toDouble();
                  final prix = (p['prix_total'] ?? 0).toDouble();

                  valeurStock += prix;

                  final nom = (p['nom_produit'] ?? "Inconnu").toString();
                  stockMap[nom] = (stockMap[nom] ?? 0) + qte;
                }

                // Déduction des quantités vendues ou sorties du stock
                for (final s in sorties) {
                  final qte = (s['quantite'] ?? 0).toDouble();
                  volumeSorties += qte;

                  final nom = (s['nom_produit'] ?? "Inconnu").toString();

                  if (stockMap.containsKey(nom)) {
                    stockMap[nom] = stockMap[nom]! - qte;
                  }
                }

                // Détection des produits dont la quantité restante est critique (inférieure à 10)
                stockMap.forEach((_, v) {
                  if (v < 10) alertes++;
                });

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // Ligne des indicateurs clés de performance (KPI)
                      Row(
                        children: [
                          _kpiCard(
                            "Stock total",
                            "${valeurStock.toStringAsFixed(2)} \$",
                            Icons.inventory,
                          ),
                          const SizedBox(width: 12),
                          _kpiCard(
                            "Sorties",
                            "${volumeSorties.toStringAsFixed(1)} Kg",
                            Icons.trending_down,
                          ),
                          const SizedBox(width: 12),
                          _kpiCard("Alertes", "$alertes", Icons.warning_amber),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Section principale : Présentation du rapport global et bouton d'impression PDF
                      _featuredReport(
                        title: "Rapport global BAN",
                        subtitle:
                            "Stock: ${valeurStock.toStringAsFixed(2)} \$ • Sorties: ${volumeSorties.toStringAsFixed(1)} Kg • Alertes: $alertes",
                        color: const Color(0xFF1B5E20),
                        onDownload: () async {
                          final pdf = pw.Document();
                          final date = DateTime.now();

                          // Structure du document PDF (Format A4)
                          pdf.addPage(
                            pw.MultiPage(
                              pageFormat: PdfPageFormat.a4,
                              margin: const pw.EdgeInsets.all(20),
                              build: (context) => [
                                // En-tête stylisé du PDF
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(12),
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.green800,
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        "RAPPORT GLOBAL BAN",
                                        style: pw.TextStyle(
                                          fontSize: 20,
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 4),
                                      pw.Text(
                                        "Généré le : ${date.day}/${date.month}/${date.year}",
                                        style: const pw.TextStyle(
                                          fontSize: 10,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                pw.SizedBox(height: 20),
                                pw.Text(
                                  "INDICATEURS",
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 10),

                                // Premier tableau PDF : Synthèse des indicateurs
                                // ignore: deprecated_member_use
                                pw.Table.fromTextArray(
                                  headers: ["Indicateur", "Valeur"],
                                  data: [
                                    [
                                      "Valeur stock",
                                      "${valeurStock.toStringAsFixed(2)} \$",
                                    ],
                                    [
                                      "Volume sorties",
                                      "${volumeSorties.toStringAsFixed(1)} Kg",
                                    ],
                                    ["Alertes", "$alertes"],
                                  ],
                                  headerStyle: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                  headerDecoration: const pw.BoxDecoration(
                                    color: PdfColors.green700,
                                  ),
                                  cellStyle: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 20),
                                pw.Text(
                                  "DETAIL STOCK",
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 10),

                                // Deuxième tableau PDF : Liste détaillée des quantités par produit
                                // ignore: deprecated_member_use
                                pw.Table.fromTextArray(
                                  headers: ["Produit", "Quantité"],
                                  data: stockMap.entries
                                      .map(
                                        (e) => [
                                          e.key,
                                          e.value.toStringAsFixed(1),
                                        ],
                                      )
                                      .toList(),
                                  headerStyle: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                  headerDecoration: const pw.BoxDecoration(
                                    color: PdfColors.green700,
                                  ),
                                  cellStyle: const pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 20),
                                pw.Divider(),
                                pw.Text(
                                  "BAN - Système de gestion agricole",
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );

                          // Déclenche l'aperçu avant impression ou le téléchargement natif du PDF
                          await Printing.layoutPdf(
                            onLayout: (format) => pdf.save(),
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      Text(
                        "EXPORTS DISPONIBLES",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Option d'exportation au format tableur CSV pour Excel
                      _exportItem(
                        "Journal des mouvements",
                        "CSV",
                        Icons.table_chart,
                        () {
                          final rows = [
                            ["Produit", "Stock"],
                            ...stockMap.entries.map((e) => [e.key, e.value]),
                          ];

                          // Conversion de la matrice en chaîne CSV exploitable
                          final csv = const ListToCsvConverter().convert(rows);
                          final bytes = utf8.encode(csv);
                          final blob = html.Blob([bytes]);
                          final url = html.Url.createObjectUrlFromBlob(blob);

                          // Simulation d'un clic sur un lien invisible pour forcer le téléchargement Web
                          html.AnchorElement(href: url)
                            ..setAttribute("download", "rapport_stock.csv")
                            ..click();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.bar_chart, color: Colors.white, size: 40),
          SizedBox(width: 12),
          Text(
            "Dashboard Rapports",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 10),
            Text(title),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _featuredReport({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onDownload,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: color, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(subtitle),
              ],
            ),
          ),
          ElevatedButton(onPressed: onDownload, child: const Text("Exporter")),
        ],
      ),
    );
  }

  Widget _exportItem(
    String title,
    String format,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text("Format: $format"),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: onTap,
        ),
      ),
    );
  }
}
