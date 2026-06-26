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

  // Met à jour le statut d'une commande et affiche un retour visuel à l'utilisateur
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
      // Écoute en direct des commandes dont le statut initial est strictement 'proforma'
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

          if (data.isEmpty) {
            return const Center(
              child: Text(
                "Aucune commande en attente de validation",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Liste espacée affichant les fiches de validation de manière fluide
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: data.length,
            // ignore: unnecessary_underscores
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = data[index];
              return _ValidationCard(
                item: item,
                onValidate: () => _updateStatus(item['id'], 'paye'),   // Validation -> Devient Payé
                onReject: () => _updateStatus(item['id'], 'dispute'),   // Rejet -> Devient Litige
              );
            },
          );
        },
      ),
    );
  }
}

// Fiche individuelle contenant les informations essentielles et les actions de validation
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
    final double price = (item['prix_total'] as num?)?.toDouble() ?? 0.0;

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
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Métadonnées de la commande (UUID tronqué pour lisibilité, nom client et prix)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "#${item['id'].toString().substring(0, 8)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  item['nom_client'] ?? "Client inconnu",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 6),
                Text(
                  "${price.toStringAsFixed(2)} \$",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          // Indicateur visuel d'attente (Badge Proforma)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          // Boutons d'actions rapides (Approuver ou Rejeter)
          Row(
            children: [
              IconButton(
                onPressed: onValidate,
                icon: const Icon(Icons.check_circle),
                color: Colors.green,
                tooltip: "Valider",
              ),
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