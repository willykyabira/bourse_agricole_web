import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class GestionEntrepots extends StatefulWidget {
  const GestionEntrepots({super.key});

  @override
  State<GestionEntrepots> createState() => _GestionEntrepotsState();
}

class _GestionEntrepotsState extends State<GestionEntrepots> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Flux en temps réel : écoute la table 'entrepots'
  // Trié par 'nom_entrepot' pour assurer la cohérence de l'affichage
  final Stream<List<Map<String, dynamic>>> _entrepotsStream = 
      Supabase.instance.client
          .from('entrepots')
          .stream(primaryKey: ['id'])
          .order('nom_entrepot');

  // --- LOGIQUE MÉTIER ---
  
  Future<void> _ajouterEntrepot(String nom, String territoire, double capacite) async {
    if (nom.isEmpty || territoire.isEmpty || capacite <= 0) {
      _showSnackBar("Veuillez remplir correctement tous les champs", Colors.orange);
      return;
    }

    try {
      await supabase.from('entrepots').insert({
        'nom_entrepot': nom.trim(), 
        'territoire': territoire.trim(),
        'capacite': capacite,
        'stock_actuel': 0, 
      });
      
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar("Nouvelle unité de stockage ajoutée en Ituri !", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Erreur de base de données : $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // --- INTERFACE UTILISATEUR ---

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "UNITÉS DE STOCKAGE (ITURI)",
      activeRoute: '/warehouses',
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _entrepotsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur de synchronisation : ${snapshot.error}"));
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warehouse_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 15),
                          Text("Aucun entrepôt enregistré pour le moment.", 
                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return _buildGrid(list);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Infrastructures de stockage", 
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey)),
            const Text("Suivi provincial des capacités", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text("NOUVEAU ENTREPOT"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> data) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 450,
        mainAxisExtent: 210,
        crossAxisSpacing: 25,
        mainAxisSpacing: 25,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final double cap = (item['capacite'] as num).toDouble();
        final double stock = (item['stock_actuel'] as num).toDouble();
        final double ratio = cap > 0 ? (stock / cap) : 0.0;
        final bool alerte = ratio >= 0.85;

        return Card(
          elevation: 5,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item['nom_entrepot'].toString().toUpperCase(), 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF1B5E20))),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: alerte ? Colors.red[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.warehouse, color: alerte ? Colors.red : const Color(0xFF1B5E20)),
                    ),
                  ],
                ),
                Text("Territoire : ${item['territoire']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Capacité : ${item['capacite']} Kg", 
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text("${(ratio * 100).toInt()}%", 
                      style: TextStyle(color: alerte ? Colors.red : Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  color: alerte ? Colors.red : const Color(0xFF1B5E20),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final nCtrl = TextEditingController();
    final tCtrl = TextEditingController();
    final cCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Enregistrer un site de stockage", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nCtrl, decoration: _inputStyle("Nom de l'entrepôt", Icons.business)),
            const SizedBox(height: 15),
            TextField(controller: tCtrl, decoration: _inputStyle("Territoire (ex: Mahagi, Aru...)", Icons.map_outlined)),
            const SizedBox(height: 15),
            TextField(controller: cCtrl, decoration: _inputStyle("Capacité maximale (Kg)", Icons.line_weight), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
          ElevatedButton(
            onPressed: () => _ajouterEntrepot(nCtrl.text, tCtrl.text, double.tryParse(cCtrl.text) ?? 0),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            child: const Text("VALIDER L'AJOUT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}