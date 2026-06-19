import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/ban_layout.dart';

class InventaireScreen extends StatelessWidget {
  const InventaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return BanLayout(
      title: "INVENTAIRE GLOBAL",
      activeRoute: '/inventaire',
      child: StreamBuilder(
        stream: supabase.from('produits').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return StreamBuilder(
            stream: supabase.from('sorties').stream(primaryKey: ['id']),
            builder: (context, snapshotS) {
              if (snapshotS.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              final produits = snapshot.data as List<Map<String, dynamic>>;
              final sorties = snapshotS.data as List<Map<String, dynamic>>;
              
              // Logique simplifiée
              return ListView(
                children: produits.map((p) {
                  double entree = double.tryParse(p['quantite'].toString()) ?? 0;
                  double sortie = sorties.where((s) => s['nom_produit'] == p['nom_produit']).fold(0, (sum, s) => sum + (double.tryParse(s['quantite'].toString()) ?? 0));
                  return ListTile(
                    title: Text(p['nom_produit']),
                    subtitle: Text("Stock : ${entree - sortie} ${p['unite_mesure']}"),
                  );
                }).toList(),
              );
            }
          );
        }
      ),
    );
  }
}