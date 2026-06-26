import 'package:flutter/material.dart';
import 'package:bourse_agricole_web/ui/widgets/ban_layout.dart';

/// Écran affichant le journal des activités du système.
class AuditLogs extends StatelessWidget {
  const AuditLogs({super.key});

  // Données d'exemple affichées dans le journal.
  final List<Map<String, String>> _logs = const [
    {
      "date": "11/05 10:45",
      "action": "Connexion",
      "user": "Willy Kyabira",
      "detail": "Admin accédé au système",
    },
    {
      "date": "11/05 09:20",
      "action": "Stock",
      "user": "JP Finance",
      "detail": "Entrée de 50 sacs de Manioc à Bunia",
    },
    {
      "date": "10/05 16:30",
      "action": "Alerte",
      "user": "Système",
      "detail": "Capacité critique à Mahagi (85%)",
    },
    {
      "date": "10/05 14:15",
      "action": "Modification",
      "user": "Admin IT",
      "detail": "Mise à jour des prix : Maïs Jaune",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BanLayout(
      title: "JOURNAL D'AUDIT & SÉCURITÉ",
      activeRoute: '/logs',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ListView.separated(
                  itemCount: _logs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildLogItem(_logs[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête du journal.
  Widget _buildLogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Activités récentes du système",
          style: TextStyle(
            color: Colors.blueGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 18),
          label: const Text("EXPORTER LES LOGS"),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  /// Construit une ligne du journal.
  Widget _buildLogItem(Map<String, String> log) {
    final Color actionColor = _getLogColor(log['action']!);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: actionColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              log['action']!.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: actionColor,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            log['detail']!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          "Utilisateur : ${log['user']} • Ituri, DRC",
          style: const TextStyle(fontSize: 12),
        ),
      ),
      trailing: Text(
        log['date']!,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// Retourne la couleur associée à chaque type d'action.
  Color _getLogColor(String action) {
    switch (action) {
      case "Alerte":
        return Colors.red;
      case "Stock":
        return Colors.orange;
      case "Modification":
        return Colors.blue;
      default:
        return const Color(0xFF1B5E20);
    }
  }
}