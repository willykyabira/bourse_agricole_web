import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

/// =======================================================
/// PAGE : VALIDATION COMMANDES (UI PRO SaaS)
/// =======================================================
class PageValidation extends StatefulWidget {
  const PageValidation({super.key});

  @override
  State<PageValidation> createState() => _PageValidationState();
}

class _PageValidationState extends State<PageValidation> {
  final _supabase = Supabase.instance.client;

  /// =======================================================
  /// UPDATE STATUT
  /// =======================================================
  Future<void> _updateStatus(dynamic id, String newStatut) async {
    try {
      await _supabase
          .from('commandes')
          .update({'statut': newStatut})
          .eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Statut mis à jour : $newStatut"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "VALIDATION DES COMMANDES",
      activeRoute: '/validation',

      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('commandes')
            .stream(primaryKey: ['id'])
            .eq('statut', 'proforma'),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          /// ================= EMPTY STATE =================
          if (data.isEmpty) {
            return const Center(
              child: Text(
                "Aucune commande en attente de validation",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),

            itemBuilder: (context, index) {
              final item = data[index];
              return _ValidationCard(
                item: item,
                onValidate: () =>
                    _updateStatus(item['id'], 'paye'),
                onReject: () =>
                    _updateStatus(item['id'], 'dispute'),
              );
            },
          );
        },
      ),
    );
  }
}

/// =======================================================
/// CARD VALIDATION (UI SaaS PRO)
/// =======================================================
class _ValidationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  const _ValidationCard({
    required this.item,
    required this.onValidate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final double price =
        (item['prix_total'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Row(
        children: [

          /// ================= INFO =================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// ID + CLIENT
                Text(
                  "#${item['id'].toString().substring(0, 8)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  item['nom_client'] ?? "Client inconnu",
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "${price.toStringAsFixed(2)} \$",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          /// ================= BADGE =================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "PROFORMA",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// ================= ACTIONS =================
          Row(
            children: [

              /// VALIDATE
              IconButton(
                onPressed: onValidate,
                icon: const Icon(Icons.check_circle),
                color: Colors.green,
                tooltip: "Valider",
              ),

              /// REJECT
              IconButton(
                onPressed: onReject,
                icon: const Icon(Icons.cancel),
                color: Colors.red,
                tooltip: "Rejeter",
              ),
            ],
          ),
        ],
      ),
    );
  }
}