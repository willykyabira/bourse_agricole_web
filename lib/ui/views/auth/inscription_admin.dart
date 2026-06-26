import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InscriptionAdmin extends StatefulWidget {
  const InscriptionAdmin({super.key});

  @override
  State<InscriptionAdmin> createState() => _InscriptionAdminState();
}

class _InscriptionAdminState extends State<InscriptionAdmin> {
  // Clé globale unique permettant d'identifier le formulaire et de déclencher sa validation
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de texte pour récupérer proprement les saisies sans dépendre des événements onChanged
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Rôle sélectionné par défaut dans le menu déroulant
  String _role = 'stock';

  // Palette graphique standardisée alignée sur l'application BAN
  static const Color _primaryColor = Color(0xFF1B5E20); // Vert BAN
  static const Color _surfaceColor = Colors.white;
  static const Color _backgroundColor = Color(0xFFF8FAFC); // Fond sobre (Slate 50)
  static const Color _textColorPrimary = Color(0xFF0F172A);

  @override
  void dispose() {
    // Libération des ressources des contrôleurs pour éviter les fuites de mémoire (Memory Leaks)
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Méthode centrale de soumission du formulaire
  void _soumettreFormulaire() {
    // Déclenche les validateurs (validator) de chaque champ du formulaire
    if (_formKey.currentState!.validate()) {
      // Étape logicielle future : Insérer ici l'appel Supabase d'authentification / profils
      final String email = _emailController.text.trim();
      final String role = _role;

      // Fermeture de la boîte de dialogue ou retour à la page précédente
      Navigator.pop(context);

      // Notification visuelle de succès à destination de l'administrateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Agent enregistré avec succès ($email - $role)",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "AJOUTER UN NOUVEL AGENT",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: 500, // Largeur fixe adaptée aux interfaces Web/Tablette (Card Design)
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)), // Bordure subtile grise
            ),
            child: Form(
              key: _formKey, // Liaison de la clé globale au widget Form
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Création de compte personnel",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: _textColorPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Attribuez des identifiants d'accès provisoires pour un nouvel employé du staff.",
                    style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  // --- CHAMP 1 : EMAIL PROFESSIONNEL ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Email professionnel",
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    // Bloc de validation de cohérence de la saisie
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Veuillez renseigner l'adresse email.";
                      }
                      // Expression régulière simple pour valider la structure d'un email
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return "Format d'adresse email invalide.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- CHAMP 2 : MOT DE PASSE PROVISOIRE ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Mot de passe provisoire",
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Veuillez définir un mot de passe.";
                      }
                      if (value.length < 6) {
                        return "Le mot de passe doit contenir au moins 6 caractères.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- CHAMP 3 : SÉLECTION DU RÔLE (STAFF UNIQUE) ---
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    style: GoogleFonts.poppins(fontSize: 14, color: _textColorPrimary, fontWeight: FontWeight.w500),
                    dropdownColor: _surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    decoration: InputDecoration(
                      labelText: "Rôle de l'agent",
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    // Liste d'options limitées strictement au personnel administratif
                    items: const [
                      DropdownMenuItem(value: 'stock', child: Text("Gestionnaire de Stock")),
                      DropdownMenuItem(value: 'finance', child: Text("Chargé de Finance")),
                    ],
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _role = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- BOUTON D'ACTION PRINCIPAL ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _soumettreFormulaire,
                      child: Text(
                        "CRÉER LE COMPTE AGENT",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}