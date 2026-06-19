import 'package:flutter/material.dart';
import 'package:bourse_agricole_web/ui/views/auth/ecran_connexion.dart';

class PageAccueilStaff extends StatefulWidget {
  const PageAccueilStaff({super.key});

  @override
  State<PageAccueilStaff> createState() => _PageAccueilStaffState();
}

class _PageAccueilStaffState extends State<PageAccueilStaff> {
  final Color darkGreen = const Color(0xFF1B5E20);

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => EcranConnexion()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: const Text("BAN STAFF - Gestion"),
        actions: [IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout))],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildMenuCard("Entrepôts", Icons.store, Colors.blue),
          _buildMenuCard("Stock / Dépôts", Icons.inventory_2, Colors.orange),
          _buildMenuCard("Finances", Icons.account_balance_wallet, Colors.green),
          _buildMenuCard("Utilisateurs", Icons.people, Colors.red),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String titre, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Logique de navigation vers les sous-modules (Finance, Stock, etc.)
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // ignore: deprecated_member_use
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

