import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class GestionUtilisateurs extends StatefulWidget {
  const GestionUtilisateurs({super.key});
  @override
  State<GestionUtilisateurs> createState() => _GestionUtilisateursState();
}

class _GestionUtilisateursState extends State<GestionUtilisateurs> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isPasswordVisible = false, _isCheckingAuth = true;
  List<Map<String, dynamic>> _entrepots = [];
  
  static const Color _primaryColor = Color(0xFF1B5E20);

  // Écoute en temps réel de la table 'profiles' triée par nom
  final Stream<List<Map<String, dynamic>>> _usersStream = 
      Supabase.instance.client.from('profiles').stream(primaryKey: ['id']).order('nom_complet');

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  // Vérification de la session utilisateur au démarrage
  Future<void> _checkAuthAndLoadData() async {
    if (supabase.auth.currentSession == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    setState(() => _isCheckingAuth = false);
    _fetchEntrepots();
  }

  // Récupération initiale de la liste des entrepôts
  Future<void> _fetchEntrepots() async {
    try {
      final response = await supabase.from('entrepots').select('id, nom_entrepot');
      setState(() => _entrepots = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Erreur entrepôts : $e");
    }
  }

  // Filtre pour distinguer le personnel administratif (Staff) des clients
  bool _isStaff(String role) => ['admin', 'stock', 'finance'].contains(role.toLowerCase());

  // Récupération textuelle du nom de l'entrepôt selon son identifiant
  String _getEntrepotName(dynamic id) {
    if (id == null) return "Non assigné";
    return _entrepots.firstWhere((item) => item['id'].toString() == id.toString(), orElse: () => {'nom_entrepot': 'Inconnu'})['nom_entrepot'];
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _primaryColor)));
    }

    return BanLayout(
      title: "GESTION DES UTILISATEURS",
      activeRoute: '/users_manage',
      child: Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Expanded(
              // Gestion de l'affichage réactif des profils
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _usersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _primaryColor));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Aucun utilisateur trouvé."));
                  }

                  // Séparation dynamique des flux : Équipe vs Clients
                  final staff = snapshot.data!.where((u) => _isStaff(u['role'] ?? '')).toList();
                  final clients = snapshot.data!.where((u) => !_isStaff(u['role'] ?? '')).toList();

                  return ListView(
                    children: [
                      if (staff.isNotEmpty) ...[
                        const _SectionTitle(title: "ÉQUIPE STAFF"),
                        ...staff.map((u) => _UserCard(
                          user: u, isStaff: true, primaryColor: _primaryColor,
                          onView: () => _showDetails(u, true),
                          onEdit: () => _showAddOrEditDialog(context, user: u),
                          onToggleStatus: () => _toggleStatut(u['id'], u['is_active'] ?? true),
                          onDelete: () => _confirmDelete(u),
                        )),
                        const SizedBox(height: 32),
                      ],
                      if (clients.isNotEmpty) ...[
                        const _SectionTitle(title: "COMPTES CLIENTS"),
                        ...clients.map((u) => _UserCard(
                          user: u, isStaff: false, primaryColor: _primaryColor,
                          onView: () => _showDetails(u, false),
                          onToggleStatus: () => _toggleStatut(u['id'], u['is_active'] ?? true),
                        )),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Utilisateurs", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text("Gérez les accès et les permissions de vos collaborateurs et clients.", style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14)),
        ],
      ),
      ElevatedButton.icon(
        onPressed: () => _showAddOrEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("NOUVEAU COMPTE", style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor, foregroundColor: Colors.white, 
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
      ),
    ],
  );

  // Modale d'affichage des caractéristiques complètes du compte
  void _showDetails(Map<String, dynamic> user, bool isStaff) {
    Map<String, String> data = {
      "Nom complet": user['nom_complet']?.toString() ?? 'N/A',
      "Email": user['email']?.toString() ?? 'N/A',
      "Téléphone": user['telephone']?.toString() ?? 'N/A',
    };
    if (isStaff) {
      data["Rôle"] = user['role']?.toString().toUpperCase() ?? 'N/A';
      data["Entrepôt"] = _getEntrepotName(user['entrepot_id']);
    } else {
      data["Adresse"] = user['adresse']?.toString() ?? 'Non renseignée';
    }

    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Détails du compte", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _primaryColor)),
        content: SizedBox(
          width: 400, 
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: data.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 120, child: Text(e.key, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[500]))),
                  Expanded(child: Text(e.value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[800]))),
                ],
              ),
            )).toList()
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))],
      )
    );
  }

  // Dialogue synthétisé gérant à la fois la création et l'édition d'agents (Évite les doublons de code)
  void _showAddOrEditDialog(BuildContext context, {Map<String, dynamic>? user}) {
    final bool isEdit = user != null;
    final nomCtrl = TextEditingController(text: isEdit ? user['nom_complet'] : "");
    final emailCtrl = TextEditingController(text: isEdit ? user['email'] : "");
    final telCtrl = TextEditingController(text: isEdit ? user['telephone'] : "");
    final passCtrl = TextEditingController();
    String selectedRole = isEdit ? (user['role'] ?? 'stock') : 'stock';
    String? selectedEntrepotId = isEdit ? user['entrepot_id']?.toString() : null;

    showDialog(context: context, builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? "MODIFIER L'UTILISATEUR" : "CRÉER UN AGENT", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _primaryColor)),
        content: SizedBox(width: 450, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildField(nomCtrl, "Nom complet", Icons.person_outline),
          const SizedBox(height: 16),
          _buildField(emailCtrl, "Email", Icons.alternate_email, type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildField(telCtrl, "Contact", Icons.phone_android, type: TextInputType.phone),
          const SizedBox(height: 16),
          _buildDropdown("Changer l'entrepôt", selectedEntrepotId, _entrepots.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e['nom_entrepot'].toString()))).toList(), (v) => setDialogState(() => selectedEntrepotId = v)),
          if (!isEdit) ...[
            const SizedBox(height: 16),
            _buildField(passCtrl, "Mot de passe", Icons.lock_outline, isPass: true, isVisible: _isPasswordVisible, onToggle: () => setDialogState(() => _isPasswordVisible = !_isPasswordVisible)),
          ],
          const SizedBox(height: 16),
          _buildDropdown("Rôle", selectedRole, const [
              DropdownMenuItem(value: 'stock', child: Text("Gestionnaire de Stock")),
              DropdownMenuItem(value: 'finance', child: Text("Chargé de Finance")),
              DropdownMenuItem(value: 'admin', child: Text("Administrateur")),
            ], (v) => setDialogState(() => selectedRole = v!)),
        ]))),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)), 
            onPressed: () {
              if (isEdit) {
                _updateUtilisateur(user['id'], {'nom_complet': nomCtrl.text, 'email': emailCtrl.text, 'telephone': telCtrl.text, 'role': selectedRole, 'entrepot_id': selectedEntrepotId});
              } else {
                _creerUtilisateur(nomCtrl.text, emailCtrl.text, telCtrl.text, passCtrl.text, selectedRole, selectedEntrepotId);
              }
            }, 
            child: Text(isEdit ? "ENREGISTRER" : "CRÉER LE COMPTE")
          ),
        ],
      ),
    ));
  }

  // --- ACTIONS SUPABASE OUVRIÈRES ---

  Future<void> _updateUtilisateur(String userId, Map<String, dynamic> data) async {
    try { 
      await supabase.from('profiles').update(data).eq('id', userId); 
      _showSnack("Mise à jour réussie", Colors.green); 
    } catch (e) { _showSnack("Erreur : $e", Colors.red); }
  }

  Future<void> _creerUtilisateur(String nom, String email, String tel, String pass, String role, String? entrepotId) async {
    if (nom.isEmpty || email.isEmpty || pass.isEmpty || entrepotId == null) { _showSnack("Champs requis", Colors.orange); return; }
    try {
      final AuthResponse res = await supabase.auth.signUp(email: email.trim(), password: pass.trim());
      if (res.user?.id != null) {
        await supabase.from('profiles').upsert({'id': res.user!.id, 'nom_complet': nom, 'email': email, 'telephone': tel, 'role': role, 'entrepot_id': entrepotId});
        if (mounted) Navigator.pop(context);
        _showSnack("Créé avec succès !", Colors.green);
      }
    } catch (e) { _showSnack("Erreur : $e", Colors.red); }
  }

  Future<void> _toggleStatut(String userId, bool currentStatus) async {
    try { await supabase.from('profiles').update({'is_active': !currentStatus}).eq('id', userId); } 
    catch (e) { _showSnack("Erreur statut", Colors.red); }
  }

  Future<void> _supprimerUtilisateur(String userId) async {
    try { await supabase.from('profiles').delete().eq('id', userId); _showSnack("Supprimé", Colors.green); } 
    catch (e) { _showSnack("Erreur : $e", Colors.red); }
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Confirmer la suppression"),
      content: Text("Supprimer définitivement ${user['nom_complet'] ?? 'cet utilisateur'} ? Cette action est irréversible."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), 
          onPressed: () { _supprimerUtilisateur(user['id']); Navigator.pop(context); }, 
          child: const Text("Supprimer")
        ),
      ],
    ));
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  // Formulaire : Champ de saisie universel
  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isPass = false, bool isVisible = false, VoidCallback? onToggle, TextInputType type = TextInputType.text}) => TextField(
    controller: ctrl, obscureText: isPass && !isVisible, keyboardType: type,
    decoration: InputDecoration(
      labelText: hint, prefixIcon: Icon(icon, color: _primaryColor, size: 22), filled: true, fillColor: Colors.grey[50], 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
      suffixIcon: isPass ? IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: onToggle) : null
    ),
  );

  // Formulaire : Menu déroulant universel
  Widget _buildDropdown(String label, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) => DropdownButtonFormField<String>(
    initialValue: value, items: items, onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label, prefixIcon: const Icon(Icons.list, color: _primaryColor, size: 22), filled: true, fillColor: Colors.grey[50], 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 1.5))
    ),
  );
}

// --- WIDGETS DE COMPOSANTS UI EXTRAITS SÉPARÉS ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16, left: 4),
    child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
  );
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isStaff;
  final Color primaryColor;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback? onDelete;

  const _UserCard({required this.user, required this.isStaff, required this.primaryColor, required this.onView, this.onEdit, required this.onToggleStatus, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final String nom = user['nom_complet'] ?? 'Anonyme';
    final bool isActive = user['is_active'] ?? true;
    final String role = user['role']?.toString().toUpperCase() ?? 'CLIENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              // ignore: deprecated_member_use
              radius: 22, backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?', style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text("${user['email'] ?? 'Sans email'} • ${user['telephone'] ?? 'N/A'}", style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StatusBadge(isActive: isActive),
                  const SizedBox(width: 12),
                  _RoleBadge(role: isStaff ? role : "CLIENT"),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(icon: Icons.remove_red_eye_outlined, color: Colors.blueGrey, tooltip: "Détails", onPressed: onView),
                if (isStaff && onEdit != null) _ActionButton(icon: Icons.edit_outlined, color: Colors.blue, tooltip: "Modifier", onPressed: onEdit!),
                _ActionButton(icon: isActive ? Icons.block : Icons.check_circle_outline, color: isActive ? Colors.orange : Colors.green, tooltip: isActive ? "Désactiver" : "Activer", onPressed: onToggleStatus),
                if (isStaff && onDelete != null) _ActionButton(icon: Icons.delete_outline, color: Colors.redAccent, tooltip: "Supprimer", onPressed: onDelete!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    // ignore: deprecated_member_use
    decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? Colors.green : Colors.redAccent)),
        const SizedBox(width: 6),
        Text(isActive ? "Actif" : "Inactif", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.green[700] : Colors.redAccent[700])),
      ],
    ),
  );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), 
    child: Text(role, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))), 
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon; final Color color; final String tooltip; final VoidCallback? onPressed;
  const _ActionButton({required this.icon, required this.color, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4.0),
    child: Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8), onTap: onPressed, 
        child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(icon, size: 20, color: onPressed == null ? Colors.grey.shade400 : color)),
      ),
    ),
  );
}