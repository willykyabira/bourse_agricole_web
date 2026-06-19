import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

// IMPORTANT : Le nom de la classe doit être EXACTEMENT celui-ci
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _logsStream = Supabase.instance.client
      .from('audit_logs')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "JOURNAUX D'AUDIT",
      activeRoute: '/logs',
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Traçabilité des actions", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey)),
            const Text("Historique des opérations système", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 20),
            
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _logsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Erreur : ${snapshot.error}"));
                    }
                    
                    final logs = snapshot.data ?? [];
                    
                    if (logs.isEmpty) {
                      return const Center(child: Text("Aucun journal d'activité trouvé."));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Utilisateur')),
                          DataColumn(label: Text('Action')),
                          DataColumn(label: Text('Détails')),
                        ],
                        rows: logs.map((log) {
                          final date = DateTime.parse(log['created_at'].toString());
                          return DataRow(cells: [
                            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(date))),
                            DataCell(Text(log['user_email'] ?? 'Système')),
                            DataCell(Text(log['action'] ?? 'N/A')),
                            DataCell(Text(log['details'] ?? '')),
                          ]);
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}