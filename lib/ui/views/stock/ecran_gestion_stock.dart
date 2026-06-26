import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';
import 'ajouter_produit.dart';

class EcranGestionStock extends StatefulWidget {
  const EcranGestionStock({super.key});

  @override
  State<EcranGestionStock> createState() => _EcranGestionStockState();
}

class _EcranGestionStockState extends State<EcranGestionStock> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _nomEntrepot = "Mon Entrepôt";

  @override
  void initState() {
    super.initState();
    _chargerDonneesInitiales();
  }

  // Récupère le nom de l'entrepôt lié à l'utilisateur connecté
  Future<void> _chargerDonneesInitiales() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Lecture du profil et de la jointure avec la table entrepots
        final profil = await _supabase
            .from('profiles')
            .select('entrepot_id, entrepots(nom_entrepot)')
            .eq('id', user.id)
            .maybeSingle();
            
        if (profil != null && profil['entrepots'] != null) {
          setState(() {
            _nomEntrepot = profil['entrepots']['nom_entrepot'];
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur de chargement: $e");
    } finally {
      // Arrête le chargement, même s'il y a eu une erreur
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // DefaultTabController gère automatiquement le changement d'onglets
    return DefaultTabController(
      length: 3,
      child: BanLayout(
        title: "ESPACE DE TRAVAIL : $_nomEntrepot",
        activeRoute: '/stock_manage',
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
            : Column(
                children: [
                  // --- BARRE D'ONGLETS ---
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: Color(0xFF1B5E20),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF1B5E20),
                      indicatorWeight: 3,
                      tabs: [
                        Tab(icon: Icon(Icons.swap_horiz), text: "MOUVEMENTS"),
                        Tab(icon: Icon(Icons.inventory_2_outlined), text: "INVENTAIRE"),
                        Tab(icon: Icon(Icons.map_outlined), text: "PROVENANCE"),
                      ],
                    ),
                  ),
                  
                  // --- CONTENU DES ONGLETS ---
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildOngletMouvements(),
                        _buildOngletInventaire(),
                        _buildOngletProvenance(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- 1. ONGLET MOUVEMENTS (Entrées/Sorties) ---
  Widget _buildOngletMouvements() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boutons d'action rapide
          Row(
            children: [
              _boutonAction("ENTRÉE PRODUIT", Icons.add_box, Colors.green, () => _ouvrirFormulaire()),
              const SizedBox(width: 20),
              _boutonAction("SORTIE / VENTE", Icons.unarchive, Colors.red, () {}),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            "HISTORIQUE RÉCENT", 
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Aucun mouvement enregistré aujourd'hui", 
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. ONGLET INVENTAIRE (Liste des produits) ---
  Widget _buildOngletInventaire() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Écoute en temps réel les changements dans la table 'produits'
      stream: _supabase.from('produits').stream(primaryKey: ['id']).order('nom_produit'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final produits = snapshot.data!;
        if (produits.isEmpty) {
          return const Center(child: Text("Le catalogue est vide. Ajoutez un produit !"));
        }

        // Génère la liste des cartes produits
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: produits.length,
          itemBuilder: (context, index) {
            final p = produits[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1B5E20), 
                  child: Icon(Icons.agriculture, color: Colors.white),
                ),
                title: Text(
                  p['nom_produit'] ?? "Produit inconnu", 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Stock : ${p['quantite']} ${p['unite_mesure'] ?? ''}"),
                trailing: Text(
                  "${p['prix_total']} \$", 
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 3. ONGLET PROVENANCE (Origine géographique) ---
  Widget _buildOngletProvenance() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 60, color: Colors.blueGrey),
          SizedBox(height: 10),
          Text("TRAÇABILITÉ DES PRODUITS", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("Origine : Mahagi, Aru, Irumu, Djugu, Mambasa", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- CONSTRUCTEUR DE BOUTON RÉUTILISABLE ---
  Widget _boutonAction(String titre, IconData icone, Color couleur, VoidCallback action) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: action,
        icon: Icon(icone, color: Colors.white),
        label: Text(titre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: couleur,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Ouvre le formulaire d'ajout sous forme de boîte de dialogue (Popup)
  void _ouvrirFormulaire() async {
    await showDialog(
      context: context,
      builder: (context) => const AjouterProduit(isDialog: true),
    );
    // Pas besoin de rafraîchir ici : le StreamBuilder de l'inventaire écoute en arrière-plan.
  }
}