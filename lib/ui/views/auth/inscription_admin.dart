import 'package:flutter/material.dart';

class InscriptionAdmin extends StatefulWidget {
  const InscriptionAdmin({super.key});
  @override
  State<InscriptionAdmin> createState() => _InscriptionAdminState();
}

class _InscriptionAdminState extends State<InscriptionAdmin> {
  final _formKey = GlobalKey<FormState>();
  String _role = 'stock';

  @override
  Widget build(BuildContext context) {
    const Color banGreen = Color(0xFF1B5E20);

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un agent"), backgroundColor: banGreen),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(decoration: const InputDecoration(labelText: "Email professionnel", border: OutlineInputBorder())),
                const SizedBox(height: 20),
                TextFormField(decoration: const InputDecoration(labelText: "Mot de passe provisoire", border: OutlineInputBorder()), obscureText: true),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 'stock', child: Text("Gestionnaire de Stock")),
                    DropdownMenuItem(value: 'finance', child: Text("Chargé de Finance")),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                  decoration: const InputDecoration(labelText: "Rôle", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agent enregistré")));
                    },
                    child: const Text("CRÉER LE COMPTE", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}


