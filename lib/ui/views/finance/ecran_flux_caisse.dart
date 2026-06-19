import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class EcranFluxCaisse extends StatefulWidget {
  const EcranFluxCaisse({super.key});
  @override
  State<EcranFluxCaisse> createState() => _EcranFluxCaisseState();
}

class _EcranFluxCaisseState extends State<EcranFluxCaisse> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "Transactions",
      activeRoute: '/payments',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              children: [
                Text("Historique des paiements", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase.from('commandes').stream(primaryKey: ['id']).order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    
                    final data = snapshot.data ?? [];
                    return ListView.separated(
                      itemCount: data.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) => _TransactionRow(item: data[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TransactionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final double total = (item['prix_total'] as num?)?.toDouble() ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(item['created_at']?.toString().substring(0, 10) ?? "--", style: GoogleFonts.inter(color: Colors.grey[600]))),
          Expanded(flex: 3, child: Text(item['nom_client'] ?? "Inconnu", style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text("${total.toStringAsFixed(2)} \$", textAlign: TextAlign.right, style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: Center(child: _StatusBadge(item['statut'] ?? ""))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paye';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isPaid ? const Color(0xFF166534) : const Color(0xFF92400E))),
    );
  }
}