import 'package:bourse_agricole_web/ui/navigation/lib/ui/views/admin/audit_logs.dart';
import 'package:bourse_agricole_web/ui/views/finance/page_disputes.dart';
import 'package:bourse_agricole_web/ui/views/finance/page_validation.dart';
import 'package:flutter/material.dart';
import '../views/auth/ecran_connexion.dart';
import '../views/finance/ecran_finance.dart';
import '../views/finance/ecran_flux_caisse.dart';
import '../views/finance/ecran_rapports_finance.dart';
// Autres imports stock et admin...
import '../views/stock/mouvements.dart';
import '../views/stock/ajouter_produit.dart';
import '../views/stock/inventaire_screen.dart';
import '../views/stock/ecran_statistiques.dart';
import '../views/stock/ecran_rapports.dart';
import '../views/stock/destockage.dart';
import '../views/admin/gestion_utilisateurs.dart';
import '../views/admin/gestion_entrepots.dart';
import '../views/admin/audit_logs.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/': case '/login': return MaterialPageRoute(builder: (_) => const EcranConnexion());
      
      // Finance (Recentré sur les commandes)
      case '/finance': return MaterialPageRoute(builder: (_) => const EcranFinance());
      case '/payments': return MaterialPageRoute(builder: (_) => const EcranFluxCaisse());
      case '/reports_finance': return MaterialPageRoute(builder: (_) => const EcranRapportsFinance());
      case '/validation': return MaterialPageRoute(builder: (_) => const PageValidation());
      case '/disputes': return MaterialPageRoute(builder: (_) => const PageDisputes());

      // Stock
      case '/mouvements': return MaterialPageRoute(builder: (_) => const MouvementsScreen());
      case '/gestion_sorties': return MaterialPageRoute(builder: (_) => const DestockageScreen());
      case '/entree_produit': return MaterialPageRoute(builder: (_) => const AjouterProduit(isDialog: false));
      case '/inventaire': return MaterialPageRoute(builder: (_) => const InventaireScreen());
      case '/reports_stock': return MaterialPageRoute(builder: (_) => const EcranRapports());

      // Admin
      case '/admin': case '/stats': return MaterialPageRoute(builder: (_) => const EcranStatistiques());
      case '/users_manage': return MaterialPageRoute(builder: (_) => const GestionUtilisateurs());
      case '/warehouses': case '/entrepots': return MaterialPageRoute(builder: (_) => const GestionEntrepots());
      case '/logs': return MaterialPageRoute(builder: (_) => const AuditLogsScreen());

      default: return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Page introuvable"))));
    }
  }
}