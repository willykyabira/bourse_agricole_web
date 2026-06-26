import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/ban_layout.dart';

/// Écran principal de gestion des sorties de stock et des ventes pour la plateforme BAN.
/// Utilise un [StatelessWidget] car les données sont rafraîchies en temps réel via un Stream Supabase.
class DestockageScreen extends StatelessWidget {
  const DestockageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation du client Supabase pour interagir avec la base de données
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "GESTION DES SORTIES / VENTES",
      activeRoute: '/gestion_sorties', // Définit la route active dans le menu latéral
      child: Container(
        padding: const EdgeInsets.all(25),
        // Le StreamBuilder écoute en continu les changements sur la table 'sorties'
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('sorties')
              .stream(primaryKey: ['id']) // Clé primaire requise par Supabase pour le streaming
              .order('created_at', ascending: false), // Trie du plus récent au plus ancien
          builder: (context, snapshot) {
            
            // Gestion de l'affichage en cas d'erreur de connexion ou de requête
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Erreur de chargement des données : ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            // Affichage d'un indicateur de chargement en attendant les premières données
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Récupération des données ou affectation d'une liste vide par défaut
            final data = snapshot.data ?? [];

            // Initialisation des variables pour le calcul des statistiques en local
            double sortiesJour = 0;
            DateTime aujourdhui = DateTime.now();

            // Parcours de la liste des sorties pour calculer le cumul du jour
            for (var item in data) {
              double qte = double.tryParse(item['quantite'].toString()) ?? 0;

              // Vérification et comparaison de la date pour isoler les sorties d'aujourd'hui
              if (item['created_at'] != null) {
                DateTime dateSortie = DateTime.parse(item['created_at'].toString());
                if (dateSortie.year == aujourdhui.year &&
                    dateSortie.month == aujourdhui.month &&
                    dateSortie.day == aujourdhui.day) {
                  sortiesJour += qte; // Cumul de la quantité sortie aujourd'hui
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bloc supérieur : Cartes d'indicateurs de performance (KPI)
                _buildQuickStats(sortiesJour, data.length),
                
                const SizedBox(height: 35),
                
                // Section Titre du tableau et Bouton d'action principal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "HISTORIQUE DES LIVRAISONS",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF4C6B8B),
                      ),
                    ),
                    // Bouton pour ouvrir le formulaire d'enregistrement (Ajout)
                    ElevatedButton.icon(
                      onPressed: () => _showSortieDialog(context),
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                      label: const Text(
                        "ENREGISTRER UNE COMMANDE / SORTIE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20), // Couleur verte thématique BAN
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Conteneur principal du tableau historique
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        // ignore: deprecated_member_use
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                      ],
                    ),
                    child: data.isEmpty
                        ? const Center(child: Text("Aucune livraison ou commande enregistrée."))
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                columns: const [
                                  DataColumn(label: Text('DATE')),
                                  DataColumn(label: Text('PRODUIT')),
                                  DataColumn(label: Text('ACHETEUR / DESTINATION')),
                                  DataColumn(label: Text('QUANTITÉ')),
                                  DataColumn(label: Text('ACTIONS')), // Colonne réservée aux boutons Modifier/Supprimer
                                ],
                                rows: data.map((item) {
                                  // Formatage simple de la date (récupère les 10 premiers caractères : AAAA-MM-JJ)
                                  final dateStr = item['created_at']?.toString() ?? '';
                                  final dateAffiche = dateStr.length >= 10 ? dateStr.substring(0, 10) : '-';

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(dateAffiche)),
                                      DataCell(Text(item['nom_produit'] ?? '-')),
                                      DataCell(Text(item['destination'] ?? 'Non spécifiée')),
                                      DataCell(Text("${item['quantite'] ?? 0} ${item['unite_mesure'] ?? 'Kg'}")),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Action Modifier : Ouvre le dialogue pré-rempli avec les données existantes
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              tooltip: "Modifier cette sortie",
                                              onPressed: () => _showSortieDialog(context, item: item),
                                            ),
                                            // Action Supprimer : Déclenche la demande de confirmation
                                            IconButton(
                                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                                              tooltip: "Supprimer cette sortie",
                                              onPressed: () => _confirmDelete(context, item['id']),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Aligne horizontalement les cartes statistiques du haut d'écran.
  Widget _buildQuickStats(double jour, int totalSorties) {
    return Row(
      children: [
        _statCard("Sorties du jour", "${jour.toStringAsFixed(1)} Kg", Icons.upload_rounded, Colors.orange),
        const SizedBox(width: 20),
        _statCard("Total des livraisons", "$totalSorties", Icons.assignment_turned_in, Colors.green),
      ],
    );
  }

  /// Génère une carte statistique individuelle stylisée.
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Boîte de dialogue dynamique mutualisée servant à l'enregistrement et à la modification.
  /// Si [item] est fourni, le formulaire passe automatiquement en mode édition (UPDATE).
  void _showSortieDialog(BuildContext context, {Map<String, dynamic>? item}) {
    final bool isEditing = item != null; // Booléen indiquant le mode (vrai si édition, faux si création)

    // Contrôleurs de texte configurés pour être vides (Ajout) ou pré-remplis (Modification)
    final nomController = TextEditingController(text: isEditing ? item['nom_produit']?.toString() : '');
    final qteController = TextEditingController(text: isEditing ? item['quantite']?.toString() : '');
    final destinationController = TextEditingController(text: isEditing ? item['destination']?.toString() : '');
    final uniteController = TextEditingController(text: isEditing ? item['unite_mesure']?.toString() : 'Kg');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Modifier la ligne de sortie" : "Enregistrer une commande / livraison"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomController, decoration: const InputDecoration(labelText: "Nom du Produit")),
              TextField(controller: qteController, decoration: const InputDecoration(labelText: "Quantité"), keyboardType: TextInputType.number),
              TextField(controller: uniteController, decoration: const InputDecoration(labelText: "Unité de mesure")),
              TextField(controller: destinationController, decoration: const InputDecoration(labelText: "Acheteur / Destination")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Ferme la boîte de dialogue sans rien faire
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Nettoyage et formatage des entrées de l'utilisateur
              final nom = nomController.text.trim();
              final qte = double.tryParse(qteController.text) ?? 0.0;
              final dest = destinationController.text.trim();
              final unite = uniteController.text.trim();

              // Validation stricte côté client avant envoi à la base de données
              if (nom.isEmpty || qte <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Veuillez remplir correctement le nom et la quantité.")),
                );
                return;
              }

              try {
                final supabase = Supabase.instance.client;
                
                // Préparation du dictionnaire de données à envoyer
                final payload = {
                  'nom_produit': nom,
                  'quantite': qte,
                  'unite_mesure': unite.isEmpty ? 'Kg' : unite,
                  'destination': dest.isEmpty ? 'Non spécifiée' : dest,
                };

                if (isEditing) {
                  // Mode Édition : Met à jour la ligne ciblée par son identifiant unique
                  await supabase.from('sorties').update(payload).eq('id', item['id']);
                } else {
                  // Mode Création : Insère une nouvelle ligne complète dans la table
                  await supabase.from('sorties').insert(payload);
                }

                // Si le widget est toujours présent à l'écran, on ferme le formulaire et on confirme le succès
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? "Sortie modifiée avec succès !" : "Sortie insérée avec succès !"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (error) {
                // Interception et affichage des erreurs éventuelles (ex: coupure réseau, contrainte SQL)
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur Supabase : $error"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(isEditing ? "Enregistrer les modifications" : "Enregistrer"),
          ),
        ],
      ),
    );
  }

  /// Boîte de dialogue de confirmation interceptant l'action avant suppression définitive.
  void _confirmDelete(BuildContext context, dynamic id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer définitivement cet enregistrement de l'historique ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Fermeture sans suppression
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () async {
              try {
                // Requête de suppression définitive basée sur l'identifiant de la ligne
                await Supabase.instance.client.from('sorties').delete().eq('id', id);
                
                if (context.mounted) {
                  Navigator.pop(context); // Ferme la pop-up de confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enregistrement supprimé."), backgroundColor: Colors.orange),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de la suppression : $error"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}