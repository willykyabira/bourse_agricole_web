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
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Constantes de design encapsulées
  static const Color _primaryColor = Color(0xFF1B5E20);
  static const double _borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "GESTION DES ENTREPÔTS",
      activeRoute: '/warehouses',
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _HeaderSection(onAdd: () => _showFormDialog()),
          const SizedBox(height: 24),
          Expanded(
            child: _WarehouseList(
  supabase: _supabase, 
  onEdit: (item) => _showFormDialog(item: item), // Utilisation d'une closure
),
          ),
        ],
      ),
    );
  }

  // --- LOGIQUE MÉTIER ---

  Future<void> _handleUpsert({
    String? id, 
    required String nom, 
    required String territoire, 
    required double capacite, 
    required String telephone, 
    required bool isEdit
  }) async {
    try {
      final payload = {
        'nom_entrepot': nom.trim(),
        'territoire': territoire.trim(),
        'capacite': capacite,
        'telephone': telephone.trim(),
      };

      if (isEdit) {
        await _supabase.from('entrepots').update(payload).eq('id', id!);
      } else {
        payload['stock_actuel'] = 0;
        await _supabase.from('entrepots').insert(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur système : ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nCtrl = TextEditingController(text: isEdit ? item['nom_entrepot'] : '');
    final tCtrl = TextEditingController(text: isEdit ? item['territoire'] : '');
    final cCtrl = TextEditingController(text: isEdit ? item['capacite'].toString() : '');
    final telCtrl = TextEditingController(text: isEdit ? (item['telephone'] ?? '') : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Modifier l'infrastructure" : "Ajouter un site"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CustomTextField(ctrl: nCtrl, label: "Nom du site", icon: Icons.business),
              _CustomTextField(ctrl: tCtrl, label: "Territoire", icon: Icons.map),
              _CustomTextField(ctrl: cCtrl, label: "Capacité (Kg)", icon: Icons.scale, isNumber: true),
              _CustomTextField(ctrl: telCtrl, label: "Téléphone", icon: Icons.phone, isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () => _handleUpsert(
              id: isEdit ? item['id'] : null,
              nom: nCtrl.text,
              territoire: tCtrl.text,
              capacite: double.tryParse(cCtrl.text) ?? 0,
              telephone: telCtrl.text,
              isEdit: isEdit,
            ),
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }
}

// --- SOUS-COMPOSANTS MODULAIRES ---

class _HeaderSection extends StatelessWidget {
  final VoidCallback onAdd;
  const _HeaderSection({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Logistique", style: GoogleFonts.poppins(color: Colors.grey)),
            Text("Parc des Entrepôts", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text("NOUVEAU SITE"),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
        ),
      ],
    );
  }
}

class _WarehouseList extends StatelessWidget {
  final SupabaseClient supabase;
  final Function(Map<String, dynamic>) onEdit;

  const _WarehouseList({required this.supabase, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('entrepots').stream(primaryKey: ['id']).order('nom_entrepot'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Erreur de connexion"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final data = snapshot.data!;
        return ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _WarehouseCard(item: data[index], onEdit: onEdit),
        );
      },
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onEdit;

  const _WarehouseCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.warehouse)),
        title: Text(item['nom_entrepot'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${item['territoire']} • ${item['capacite']} Kg"),
        trailing: IconButton(onPressed: () => onEdit(item), icon: const Icon(Icons.edit)),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isNumber;

  const _CustomTextField({required this.ctrl, required this.label, required this.icon, this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}