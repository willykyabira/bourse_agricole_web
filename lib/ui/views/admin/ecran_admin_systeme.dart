import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';
import '../../../data/services/admin_service.dart';

class EcranAdminSysteme extends StatefulWidget {
  const EcranAdminSysteme({super.key});

  @override
  State<EcranAdminSysteme> createState() => _EcranAdminSystemeState();
}

class _EcranAdminSystemeState extends State<EcranAdminSysteme> {
  final AdminService _adminService = AdminService();

  // --- LOGIQUE DE DIALOGUE (AJOUT / ÉDITION / SUPPRESSION) ---

  void _confirmerSuppression(String id, String nom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirmer la suppression"),
        content: Text("Voulez-vous vraiment retirer l'accès à $nom ? cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _adminService.supprimerUtilisateur(id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utilisateur supprimé")));
                }
              } catch (e) {
                debugPrint("Erreur suppression: $e");
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _ouvrirFormulaireAjout() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nomController = TextEditingController();
    final telController = TextEditingController();
    String selectedRole = 'stock';
    String? selectedEntrepotId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Nouvel Agent BAN", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
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
                  decoration: const InputDecoration(labelText: "Rôle", border: OutlineInputBorder()),
                  items: ['client', 'finance', 'admin', 'stock'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                ),
                const SizedBox(height: 15),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _adminService.fetchEntrepots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Affectation", border: OutlineInputBorder()),
                      items: snapshot.data!.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e['nom_entrepot'] ?? ""))).toList(),
                      onChanged: (val) => setDialogState(() => selectedEntrepotId = val),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () async {
                try {
                  await _adminService.creerAgent(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    nom: nomController.text.trim(),
                    tel: telController.text.trim(),
                    role: selectedRole,
                    entrepotId: selectedEntrepotId,
                  );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                }
              },
              child: const Text("Créer l'accès", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- CONSTRUCTION DE L'UI ---

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "ADMINISTRATION DU SYSTÈME",
      activeRoute: '/admin',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: 40),
            _buildStatsGrid(),
            const SizedBox(height: 40),
            Text("GESTION DES UTILISATEURS", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            _buildUserTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tableau de bord de gestion", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            Text("Willy Kyabira", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
            const SizedBox(height: 5),
            Container(width: 80, height: 4, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10))),
          ],
        ),
        // Le bouton est ici, le menu profil est géré par BanLayout
        ElevatedButton.icon(
          onPressed: _ouvrirFormulaireAjout,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text("NOUVEL AGENT", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return FutureBuilder<Map<String, int>>(
      future: _adminService.fetchStats(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'users': 0, 'entrepots': 0};
        return Wrap(
          spacing: 20, runSpacing: 20,
          children: [
            _statCard("Utilisateurs", "${data['users']}", Icons.group, Colors.blue),
            _statCard("Entrepôts", "${data['entrepots']}", Icons.store, Colors.green),
            _statCard("Alertes", "0", Icons.notifications_active, Colors.orange),
            _statCard("Flux Ituri", "Stable", Icons.speed, Colors.teal),
          ],
        );
      },
    );
  }

  Widget _buildUserTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _adminService.fluxUtilisateurs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
          final users = snapshot.data!;
          return DataTable(
            columns: const [
              DataColumn(label: Text("AGENT")),
              DataColumn(label: Text("RÔLE")),
              DataColumn(label: Text("TÉLÉPHONE")),
              DataColumn(label: Text("ACTIONS")),
            ],
            rows: users.map((u) => DataRow(cells: [
              DataCell(Text(u['nom_complet'] ?? "Inconnu")),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(5)),
                child: Text(u['role'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
              )),
              DataCell(Text(u['telephone'] ?? "-")),
              DataCell(Row(
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () {}), 
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _confirmerSuppression(u['id'], u['nom_complet'])),
                ],
              )),
            ])).toList(),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color col) {
    return Container(
      width: 240, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: col, size: 30),
          const SizedBox(height: 15),
          Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      ),
    );
  }
}