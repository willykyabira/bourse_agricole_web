import 'package:flutter/material.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

class CommunauteClients extends StatelessWidget {
  const CommunauteClients({super.key});

  final List<Map<String, String>> _partenaires = const [
    {"nom": "Coopérative AMANI", "type": "Producteur", "lieu": "Mahagi", "tel": "+243 812..."},
    {"nom": "Éts. KASSAI & Fils", "type": "Acheteur Grossiste", "lieu": "Bunia", "tel": "+243 997..."},
    {"nom": "Groupement des Agriculteurs", "type": "Producteur", "lieu": "Aru", "tel": "+243 854..."},
    {"nom": "Union de Mambasa", "type": "Producteur", "lieu": "Mambasa", "tel": "+243 821..."},
  ];

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "COMMUNAUTÉ DES CLIENTS & PARTENAIRES",
      activeRoute: '/clients',
      child: Column(
        children: [
          // Barre de recherche et actions
          _buildTopBar(),
          const SizedBox(height: 25),
          
          // Grille des partenaires
          Expanded(
            child: _buildClientsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: "Rechercher par nom, territoire ou type...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text("NOUVEAU PARTENAIRE"),
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

  Widget _buildClientsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisExtent: 130,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _partenaires.length,
      itemBuilder: (context, index) {
        final p = _partenaires[index];
        final bool isProd = p['type'] == "Producteur";

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: isProd ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                child: Icon(isProd ? Icons.agriculture : Icons.storefront, 
                            color: isProd ? Colors.green : Colors.blue),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p['nom']!, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                    Text(p['type']!, 
                      style: TextStyle(color: isProd ? Colors.green : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(p['lieu']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF1B5E20)),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}