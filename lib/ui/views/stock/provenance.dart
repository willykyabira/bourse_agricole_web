import 'package:flutter/material.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class ProvenanceScreen extends StatelessWidget {
  const ProvenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "TRAÇABILITÉ ET PROVENANCE",
      activeRoute: '/provenance',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text("ORIGINE DES PRODUITS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            Text("Collecte en cours : Mahagi, Aru, Irumu, Djugu, Mambasa", 
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}