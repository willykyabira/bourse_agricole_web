import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class PageValidation extends StatefulWidget {
  const PageValidation({super.key});

  @override
  State<PageValidation> createState() => _PageValidationState();
}

class _PageValidationState extends State<PageValidation> {
  final _supabase = Supabase.instance.client;

  Future<void> _updateStatus(dynamic id, String newStatut) async {
    try {
      await _supabase.from('commandes').update({'statut': newStatut}).eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Statut mis à jour en : $newStatut")),
      );
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur technique : $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "À VALIDER",
      activeRoute: '/validation',
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('commandes').stream(primaryKey: ['id']).eq('statut', 'proforma'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune commande en attente de validation."));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Acheteur")),
                  DataColumn(label: Text("Montant Total")),
                  DataColumn(label: Text("Statut")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: data.map((item) {
                  final price = (item['prix_total'] as num?)?.toDouble() ?? 0.0;
                  
                  return DataRow(cells: [
                    DataCell(Text("#${item['id'].toString().substring(0, 8)}")),
                    DataCell(Text(item['nom_client'] ?? "Inconnu")),
                    DataCell(Text("${price.toStringAsFixed(2)} \$")),
                    DataCell(const Chip(label: Text("Proforma"))),
                    DataCell(Row(children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: "Valider",
                        onPressed: () => _updateStatus(item['id'], 'paye'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: "Litige",
                        onPressed: () => _updateStatus(item['id'], 'dispute'),
                      ),
                    ])),
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