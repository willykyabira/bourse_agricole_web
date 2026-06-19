import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class TableauDeBordAdmin extends StatefulWidget {
  const TableauDeBordAdmin({super.key});

  @override
  State<TableauDeBordAdmin> createState() => _TableauDeBordAdminState();
}

class _TableauDeBordAdminState extends State<TableauDeBordAdmin> {
  final _supabase = Supabase.instance.client;

  // --- LOGIQUE DE CRÉATION D'AGENT (MOTEUR DU SYSTÈME) ---
  void _ouvrirFormulaireAjoutAgent() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nomController = TextEditingController();
    final telController = TextEditingController();
    String selectedRole = 'client';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Nouvel Utilisateur BAN", 
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nomController, "Nom complet", Icons.person),
                _buildField(telController, "Téléphone", Icons.phone),
                _buildField(emailController, "Email", Icons.email),
                _buildField(passwordController, "Mot de passe", Icons.lock, isPass: true),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: "Rôle Système"),
                  items: ['client', 'finance', 'admin', 'stock']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                try {
                  // ✅ DÉCLENCHE LE TRIGGER SQL VIA AUTH SIGNUP
                  await _supabase.auth.signUp(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    data: {
                      'nom_complet': nomController.text.trim(),
                      'telephone': telController.text.trim(),
                      'role': selectedRole,
                    },
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Agent créé et synchronisé avec succès !"), backgroundColor: Colors.green)
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur système: $e"), backgroundColor: Colors.red)
                  );
                }
              },
              child: const Text("Créer l'accès", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "TABLEAU DE BORD - ADMINISTRATION",
      activeRoute: '/admin',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ENTÊTE PERSONNALISÉE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWelcomeSection("MR. WILLY KYABIRA"),
                ElevatedButton.icon(
                  onPressed: _ouvrirFormulaireAjoutAgent,
                  icon: const Icon(Icons.add_moderator),
                  label: const Text("AJOUTER UN AGENT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            const Text("STATISTIQUES GÉNÉRALES (PROVINCE DE L'ITURI)", 
              style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 25),
            
            // --- GRILLE DE STATISTIQUES ---
            _buildQuickStats(),
            
            const SizedBox(height: 40),
            _buildSystemStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Heureux de vous revoir,", style: TextStyle(color: Colors.black54, fontSize: 14)),
        Text(name, style: GoogleFonts.poppins(color: const Color(0xFF1B5E20), fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(width: 100, height: 6, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10))),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Wrap(
      spacing: 25, runSpacing: 25,
      children: [
        _statCard("Utilisateurs", "124", Icons.people, Colors.blue),
        _statCard("Entrepôts", "8", Icons.warehouse, Colors.green),
        _statCard("Alertes", "3", Icons.warning_amber_rounded, Colors.orange),
        _statCard("Volume Global", "1.2k T", Icons.analytics, Colors.purple),
      ],
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Container(
      width: 260, padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 20),
          Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSystemStatusSection() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.green.shade100)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green),
              SizedBox(width: 10),
              Text("Statut du Système BAN ITURI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B5E20))),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "La plateforme est actuellement synchronisée. L'inscription de nouveaux agents via ce tableau de bord "
            "active automatiquement les permissions de sécurité définies dans le schéma PostgreSQL de Supabase. "
            "Chaque nouvel accès est immédiatement opérationnel sur le terrain (Bunia, Mahagi, Aru).",
            style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.6, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}