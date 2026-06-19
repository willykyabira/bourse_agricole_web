import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class PageDisputes extends StatefulWidget {
  const PageDisputes({super.key});

  @override
  State<PageDisputes> createState() => _PageDisputesState();
}

class _PageDisputesState extends State<PageDisputes> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fonction pour résoudre un litige
  Future<void> _resolveDispute(int id, String finalStatus) async {
    try {
      // CORRECTION ICI : 'statut' au lieu de 'status'
      await _supabase
          .from('commandes')
          .update({'statut': finalStatus}) 
          .eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Litige traité : commande passée en $finalStatus")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "GESTION DES LITIGES",
      activeRoute: '/disputes',
      child: StreamBuilder<List<Map<String, dynamic>>>(
        // CORRECTION ICI : 'statut' au lieu de 'status'
        stream: _supabase
            .from('commandes')
            .stream(primaryKey: ['id'])
            .eq('statut', 'dispute')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final List<Map<String, dynamic>> data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Text(
                "Aucun litige en cours.",
                style: GoogleFonts.poppins(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Client")),
                  DataColumn(label: Text("Montant")),
                  DataColumn(label: Text("Action")),
                ],
                rows: data.map((Map<String, dynamic> item) {
                  final dynamic rawPrice = item['prix_total'];
                  final double price = (rawPrice is num) ? rawPrice.toDouble() : 0.0;
                  
                  final String date = item['created_at']?.toString().split('T')[0] ?? "N/A";
                  final String clientName = (item['nom_client'] ?? "Inconnu").toString();

                  return DataRow(cells: [
                    DataCell(Text(date)),
                    DataCell(Text(clientName)),
                    // Note: Concaténation simple pour éviter tout conflit avec le caractère $
                    DataCell(Text(price.toStringAsFixed(2) + " \$")),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
                            tooltip: "Valider malgré le litige",
                            onPressed: () => _resolveDispute(item['id'] as int, 'validated'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            tooltip: "Annuler la commande",
                            onPressed: () => _resolveDispute(item['id'] as int, 'cancelled'),
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}