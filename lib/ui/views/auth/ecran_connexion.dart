import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});
  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  // Clé du formulaire et contrôleurs de saisie
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false, _obscureText = true;

  // Couleurs de la charte graphique BAN
  static const Color banGreen = Color(0xFF1B5E20), banBlue = Color(0xFF1A237E), banCardBg = Color(0xFFF1F3F4);

  // Méthode principale d'authentification et de routage
  Future<void> _verifierConnexion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null && mounted) {
        final userData = await Supabase.instance.client.from('profiles').select('role').eq('id', res.user!.id).single();
        String role = userData['role'].toString().toLowerCase();

        // Routage automatique par dictionnaire selon le rôle
        final routes = {'admin': '/admin', 'finance': '/finance', 'stock': '/mouvements'};
        Navigator.pushReplacementNamed(context, routes[role] ?? '/');
      }
    } on AuthException {
      _notifierErreur("Email ou mot de passe incorrect.");
    } on Exception catch (e) {
      _notifierErreur(e.toString().contains("ClientException") || e.toString().contains("Failed to fetch")
          ? "Problème de connexion. Vérifiez votre internet."
          : "Une erreur technique est survenue.");
    } finally { // <-- Correction ici : "finally" avec deux 'l'
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Barre d'alerte en cas d'erreur (SnackBar)
  void _notifierErreur(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 950; // Seuil d'affichage PC

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [banGreen, banBlue])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildLoginCard(), if (isDesktop) _buildServicesPanel()],
            ),
          ),
        ),
      ),
    );
  }

  // Bloc du formulaire de connexion (Gauche)
  Widget _buildLoginCard() => Container(
    width: 420, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
    decoration: BoxDecoration(color: banCardBg, borderRadius: BorderRadius.circular(28)),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: banGreen, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.eco, color: Colors.white, size: 40)),
              const SizedBox(height: 20),
              Text("BOURSE AGRICOLE NUMERIQUE", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: banGreen)),
            ]),
          ),
          const SizedBox(height: 45),
          _buildLabel("IDENTIFIANT"),
          _buildInputField(controller: _emailController, hint: "votre@email.cd", validator: (v) => (v == null || v.isEmpty) ? "Veuillez entrer votre email" : null),
          const SizedBox(height: 25),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildLabel("MOT DE PASSE"),
            Text("Mot de passe oublié ?", style: TextStyle(color: banBlue.withOpacity(0.8), fontSize: 11)),
          ]),
          _buildInputField(controller: _passwordController, hint: "********", isPassword: true, validator: (v) => (v == null || v.isEmpty) ? "Veuillez entrer votre mot de passe" : null),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifierConnexion,
              style: ElevatedButton.styleFrom(backgroundColor: banBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Se connecter", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );

  // Panneau latéral d'information (Droit - Desktop uniquement)
  Widget _buildServicesPanel() => Container(
    width: 480, margin: const EdgeInsets.only(left: 70),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("BAN, Bourse Agricole Numérique, une plateforme numérique facilitant la vente et l’achat de produits agricoles en Ituri", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
      const SizedBox(height: 40),
      _buildServiceBox(Icons.inventory_2_outlined, "Gestion des stocks", "Supervision précise des inventaires agricoles."),
      _buildServiceBox(Icons.account_balance_wallet_outlined, "Gestion financière", "Contrôle des flux et paiements des coopératives."),
      _buildServiceBox(Icons.admin_panel_settings_outlined, "Administration système", "Pilotage des accès et rapports de la province de l'Ituri."),
    ]),
  );

  // Widget d'affichage pour chaque ligne de service
  Widget _buildServiceBox(IconData icon, String title, String desc) => Container(
    margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: banGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 24)),
      const SizedBox(width: 20),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
    ]),
  );

  // Libellé indicatif au-dessus des inputs
  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)));

  // Design atomique et réutilisable pour les champs d'entrée
  Widget _buildInputField({required TextEditingController controller, required String hint, bool isPassword = false, String? Function(String?)? validator}) => TextFormField(
    controller: controller, obscureText: isPassword && _obscureText, validator: validator,
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.black26, fontSize: 14), filled: true, fillColor: Colors.white,
      suffixIcon: isPassword ? IconButton(icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.black26, size: 18), onPressed: () => setState(() => _obscureText = !_obscureText)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
    ),
  );
}