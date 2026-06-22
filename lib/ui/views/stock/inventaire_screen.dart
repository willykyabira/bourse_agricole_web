import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/ban_layout.dart';

class InventaireScreen extends StatelessWidget {
  const InventaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "INVENTAIRE GLOBAL",
      activeRoute: '/inventaire',

      /// =====================================================
      /// STREAM PRODUITS (ENTRÉES)
      /// =====================================================
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('produits').stream(primaryKey: ['id']),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          /// =====================================================
          /// STREAM SORTIES
          /// =====================================================
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('sorties').stream(primaryKey: ['id']),

            builder: (context, snapshotS) {
              if (!snapshotS.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final produits = snapshot.data!;
              final sorties = snapshotS.data!;

              /// =====================================================
              /// CALCUL INVENTAIRE
              /// =====================================================
              return SingleChildScrollView(
                padding: const EdgeInsets.all(25),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 20),

                    /// ================= TABLE =================
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                          )
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),

                        child: Column(
                          children: [
                            /// HEADER TABLE
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.grey.shade100,
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "PRODUIT",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "STOCK",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// ROWS
                            Column(
                              children: produits.map((p) {
                                final entree =
                                    double.tryParse(p['quantite'].toString()) ?? 0;

                                final sortie = sorties
                                    .where((s) =>
                                        s['nom_produit'] == p['nom_produit'])
                                    .fold<double>(
                                      0,
                                      (sum, s) =>
                                          sum +
                                          (double.tryParse(
                                                  s['quantite'].toString()) ??
                                              0),
                                    );

                                final stock = entree - sortie;

                                return _buildRow(
                                  name: p['nom_produit'] ?? 'Inconnu',
                                  stock: stock,
                                  unit: p['unite_mesure'] ?? '',
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =====================================================
  // HEADER UI
  // =====================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.white, size: 40),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Inventaire en temps réel",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Entrées - Sorties - Stock actuel",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          )
        ],
      ),
    );
  }

  // =====================================================
  // ROW ITEM (ERP STYLE)
  // =====================================================
  Widget _buildRow({
    required String name,
    required double stock,
    required String unit,
  }) {
    final isLow = stock < 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),

      child: Row(
        children: [
          /// PRODUIT
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          /// STOCK BADGE
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLow ? Colors.red.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  "${stock.toStringAsFixed(1)} $unit",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLow ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}