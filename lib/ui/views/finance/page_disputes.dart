import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

/// =======================================================
/// PAGE : GESTION DES LITIGES (UI PRO SaaS)
/// =======================================================
class PageDisputes extends StatefulWidget {
  const PageDisputes({super.key});

  @override
  State<PageDisputes> createState() => _PageDisputesState();
}

class _PageDisputesState extends State<PageDisputes> {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// =======================================================
  /// RESOLUTION LITIGE
  /// =======================================================
  Future<void> _resolveDispute(int id, String finalStatus) async {
    try {
      await _supabase
          .from('commandes')
          .update({'statut': finalStatus})
          .eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Litige traité : $finalStatus"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

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
      title: "CENTRE DES LITIGES",
      activeRoute: '/disputes',

      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('commandes')
            .stream(primaryKey: ['id'])
            .eq('statut', 'dispute')
            .order('created_at', ascending: false),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          /// ================= EMPTY STATE =================
          if (data.isEmpty) {
            return Center(
              child: Text(
                "Aucun litige actif",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          /// ================= LIST =================
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: data.length,
            // ignore: unnecessary_underscores
            separatorBuilder: (_, __) => const SizedBox(height: 12),

            itemBuilder: (context, index) {
              return _DisputeCard(
                item: data[index],
                onValidate: () =>
                    _resolveDispute(data[index]['id'], 'validated'),
                onCancel: () =>
                    _resolveDispute(data[index]['id'], 'cancelled'),
              );
            },
          );
        },
      ),
    );
  }
}

/// =======================================================
/// CARD LITIGE (UI SaaS PRO)
/// =======================================================
class _DisputeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onValidate;
  final VoidCallback onCancel;

  const _DisputeCard({
    required this.item,
    required this.onValidate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final double price =
        (item['prix_total'] as num?)?.toDouble() ?? 0.0;

    final String date =
        item['created_at']?.toString().split('T')[0] ?? "--";

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
          )
        ],

        // ignore: deprecated_member_use
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),

      child: Row(
        children: [

          /// ================= INFO =================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// CLIENT
                Text(
                  item['nom_client'] ?? "Client inconnu",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                /// DATE
                Text(
                  "Date: $date",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                /// MONTANT
                Text(
                  "${price.toStringAsFixed(2)} \$",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          /// ================= BADGE =================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "LITIGE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC62828),
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// ================= ACTIONS =================
          Row(
            children: [

              /// VALIDATE
              IconButton(
                tooltip: "Valider commande",
                onPressed: onValidate,
                icon: const Icon(Icons.check_circle),
                color: Colors.green,
              ),

              /// CANCEL
              IconButton(
                tooltip: "Annuler commande",
                onPressed: onCancel,
                icon: const Icon(Icons.cancel),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}