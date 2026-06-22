import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

/// =======================================================
/// TRANSACTIONS FINANCIÈRES (UI SAA S PREMIUM)
/// =======================================================
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
      title: "TRANSACTIONS",
      activeRoute: '/payments',

      /// ================= BACKGROUND =================
      child: Container(
        color: const Color(0xFFF6F8FB),

        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// ================= HEADER =================
              _Header(),

              const SizedBox(height: 20),

              /// ================= TABLE CARD =================
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                      )
                    ],
                  ),

                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('commandes')
                        .stream(primaryKey: ['id'])
                        .order('created_at', ascending: false),

                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final data = snapshot.data!;

                      if (data.isEmpty) {
                        return const Center(
                          child: Text("Aucune transaction"),
                        );
                      }

                      return Column(
                        children: [
                          _TableHeader(),
                          const Divider(height: 1),

                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: data.length,
                              itemBuilder: (context, i) {
                                return _TransactionRow(data[i], i);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================================================
/// HEADER DASHBOARD (STYLE SAAS)
/// =======================================================
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B5E20),
            const Color(0xFF2E7D32),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Flux de caisse",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Suivi des transactions en temps réel",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

/// =======================================================
/// TABLE HEADER (MODERNE)
/// =======================================================
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _h("DATE", 2),
          _h("CLIENT", 3),
          _h("MONTANT", 2, alignRight: true),
          _h("STATUT", 2, center: true),
        ],
      ),
    );
  }

  Widget _h(String t, int flex,
      {bool alignRight = false, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        textAlign: alignRight
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// =======================================================
/// ROW TRANSACTION (STYLE CARD LIST PRO)
/// =======================================================
class _TransactionRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const _TransactionRow(this.item, this.index);

  @override
  Widget build(BuildContext context) {
    final double total =
        (item['prix_total'] as num?)?.toDouble() ?? 0.0;

    final isEven = index.isEven;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),

      child: Row(
        children: [

          /// DATE
          Expanded(
            flex: 2,
            child: Text(
              item['created_at']?.toString().substring(0, 10) ?? "--",
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),

          /// CLIENT
          Expanded(
            flex: 3,
            child: Text(
              item['nom_client'] ?? "Inconnu",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          /// MONTANT
          Expanded(
            flex: 2,
            child: Text(
              "${total.toStringAsFixed(2)} \$",
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
          ),

          /// STATUS
          Expanded(
            flex: 2,
            child: Center(
              child: _Badge(item['statut'] ?? ""),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// BADGE STATUS (SAAS STYLE PILL)
/// =======================================================
class _Badge extends StatelessWidget {
  final String status;

  const _Badge(this.status);

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final ok = s == "paye" || s == "paid";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFE7F7ED) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ok ? const Color(0xFF166534) : const Color(0xFF9A3412),
        ),
      ),
    );
  }
}