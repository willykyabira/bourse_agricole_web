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
  bool _isPasswordVisible = false;
  
  // Liste pour stocker les entrepôts récupérés
  List<Map<String, dynamic>> _entrepots = [];

  // Écoute en temps réel de la table 'profiles'
  final Stream<List<Map<String, dynamic>>> _usersStream = 
      Supabase.instance.client.from('profiles').stream(primaryKey: ['id']).order('nom_complet');

  @override
  void initState() {
    super.initState();
    _fetchEntrepots();
  }

  // Récupération des entrepôts pour le menu déroulant
  Future<void> _fetchEntrepots() async {
    try {
      final data = await supabase.from('entrepots').select('id, nom');
      setState(() {
        _entrepots = data;
      });
    } catch (e) {
      debugPrint("Erreur chargement entrepôts: $e");
    }
  }

  // --- LOGIQUE DE CRÉATION ET SYNCHRONISATION ---
  Future<void> _creerUtilisateur(String nom, String email, String tel, String pass, String role, String? entrepotId) async {
    if (nom.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnack("Veuillez remplir les champs obligatoires", Colors.orange);
      return;
    }

    try {
      // ÉTAPE 1 : Création dans Supabase Auth
      final AuthResponse res = await supabase.auth.signUp(
        email: email.trim(),
        password: pass.trim(),
      );

      final String? userId = res.user?.id;

      if (userId != null) {
        // ÉTAPE 2 : UPSERT (Crée ou met à jour si l'ID existe déjà)
        await supabase.from('profiles').upsert({
          'id': userId,
          'nom_complet': nom.trim(),
          'email': email.trim(),
          'telephone': tel.trim(),
          'role': role,
          'entrepot_id': entrepotId, // Liaison avec l'entrepôt choisi
        });

        if (mounted) {
          Navigator.pop(context);
          _showSnack("Compte $nom créé avec succès !", Colors.green);
        }
      }
    } on AuthException catch (e) {
      _showSnack("Erreur Auth: ${e.message}", Colors.red);
    } catch (e) {
      _showSnack("Erreur de synchronisation : $e", Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "GESTION DES UTILISATEURS",
      activeRoute: '/users_manage',
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            _buildTopBanner(),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Comptes BAN enregistrés", 
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                          ElevatedButton.icon(
                            onPressed: () => _showAddUserDialog(context),
                            icon: const Icon(Icons.person_add),
                            label: const Text("NOUVEAU COMPTE"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _usersStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text("Erreur de flux : ${snapshot.error}"));
                          }
                          final users = snapshot.data ?? [];
                          if (users.isEmpty) return const Center(child: Text("Aucun compte trouvé."));
                          return _buildUserList(users);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final TextEditingController nomCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController telCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    
    String selectedRole = 'stock';
    String? selectedEntrepotId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("CRÉER UN AGENT", 
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(nomCtrl, "Nom complet de l'agent", Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildField(emailCtrl, "Email professionnel", Icons.alternate_email, type: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildField(telCtrl, "Contact (Ituri)", Icons.phone_android, type: TextInputType.phone),
                  const SizedBox(height: 12),
                  
                  // Menu déroulant Entrepôt
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration("Choisir un entrepôt", Icons.store_mall_directory_outlined),
                    value: selectedEntrepotId,
                    items: _entrepots.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e['nom']))).toList(),
                    onChanged: (v) => setDialogState(() => selectedEntrepotId = v),
                  ),
                  const SizedBox(height: 12),

                  _buildField(passCtrl, "Mot de passe temporaire", Icons.lock_outline, 
                    isPass: true, 
                    isVisible: _isPasswordVisible, 
                    onToggle: () => setDialogState(() => _isPasswordVisible = !_isPasswordVisible)),
                  const SizedBox(height: 20),
                  
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: _inputDecoration("Attribuer un rôle", Icons.verified_user_outlined),
                    items: const [
                      DropdownMenuItem(value: 'stock', child: Text("Gestionnaire de Stock")),
                      DropdownMenuItem(value: 'finance', child: Text("Chargé de Finance")),
                      DropdownMenuItem(value: 'admin', child: Text("Administrateur")),
                    ],
                    onChanged: (v) => setDialogState(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
            ElevatedButton(
              onPressed: () => _creerUtilisateur(nomCtrl.text, emailCtrl.text, telCtrl.text, passCtrl.text, selectedRole, selectedEntrepotId),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              child: const Text("CRÉER L'ACCÈS", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withOpacity(0.05), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.2))
      ),
      child: Row(children: [
        const Icon(Icons.shield_outlined, color: Color(0xFF1B5E20), size: 24), 
        const SizedBox(width: 15), 
        Expanded(child: Text("Centre de gestion des identités BAN.", 
          style: GoogleFonts.poppins(color: const Color(0xFF1B5E20), fontSize: 13)))
      ]),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: users.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final u = users[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1), 
            child: Text(u['nom_complet']?[0] ?? '?', 
              style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold))),
          title: Text(u['nom_complet'] ?? 'Anonyme', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${u['role'].toString().toUpperCase()} • ${u['email']}"),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isPass = false, bool isVisible = false, VoidCallback? onToggle, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass && !isVisible,
      keyboardType: type,
      decoration: _inputDecoration(hint, icon).copyWith(
        suffixIcon: isPass ? IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off), onPressed: onToggle) : null
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, 
      prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)), 
      filled: true, 
      fillColor: Colors.grey[50], 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2))
    );
  }
}