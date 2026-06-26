import 'package:bourse_agricole_web/ui/navigation/lib/ui/views/admin/audit_logs.dart';
import 'package:flutter/material.dart';

// Authentification
import '../views/auth/ecran_connexion.dart';

// Finance
import '../views/finance/ecran_finance.dart';
import '../views/finance/ecran_flux_caisse.dart';
import '../views/finance/ecran_rapports_finance.dart';
import '../views/finance/page_disputes.dart';
import '../views/finance/page_validation.dart';

// Stock
import '../views/stock/ajouter_produit.dart';
import '../views/stock/destockage.dart';
import '../views/stock/ecran_rapports.dart';
import '../views/stock/ecran_statistiques.dart';
import '../views/stock/inventaire_screen.dart';
import '../views/stock/mouvements.dart';

// Administration
import '../views/admin/gestion_entrepots.dart';
import '../views/admin/gestion_utilisateurs.dart';
import '../views/admin/statistiques_admin.dart';

/// Gère la navigation entre les différentes pages de l'application.
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ================= AUTHENTIFICATION =================

      case '/':
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const EcranConnexion(),
        );

      // ================= FINANCE =================

      case '/finance':
        return MaterialPageRoute(
          builder: (_) => const EcranFinance(),
        );

      case '/payments':
        return MaterialPageRoute(
          builder: (_) => const EcranFluxCaisse(),
        );

      case '/reports_finance':
        return MaterialPageRoute(
          builder: (_) => const EcranRapportsFinance(),
        );

      case '/validation':
        return MaterialPageRoute(
          builder: (_) => const PageValidation(),
        );

      case '/disputes':
        return MaterialPageRoute(
          builder: (_) => const PageDisputes(),
        );

      // ================= STOCK =================

      case '/mouvements':
        return MaterialPageRoute(
          builder: (_) => const MouvementsScreen(),
        );

      case '/gestion_sorties':
        return MaterialPageRoute(
          builder: (_) => const DestockageScreen(),
        );

      case '/entree_produit':
        return MaterialPageRoute(
          builder: (_) => const AjouterProduit(
            isDialog: false,
          ),
        );

      case '/inventaire':
        return MaterialPageRoute(
          builder: (_) => const InventaireScreen(),
        );

      case '/reports_stock':
        return MaterialPageRoute(
          builder: (_) => const EcranRapports(),
        );

      case '/stats_stock':
        return MaterialPageRoute(
          builder: (_) => const EcranStatistiques(),
        );

      // ================= ADMINISTRATION =================

      case '/admin':
      case '/stats':
        return MaterialPageRoute(
          builder: (_) => const StatistiquesAdmin(),
        );

      case '/users_manage':
        return MaterialPageRoute(
          builder: (_) => const GestionUtilisateurs(),
        );

      case '/warehouses':
      case '/entrepots':
        return MaterialPageRoute(
          builder: (_) => const GestionEntrepots(),
        );

      case '/logs':
        return MaterialPageRoute(
          builder: (_) => const AuditLogsScreen(),
        );

      // ================= PAGE PAR DÉFAUT =================

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text("Page introuvable"),
            ),
          ),
        );
    }
  }
}