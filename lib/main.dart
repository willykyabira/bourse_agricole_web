import 'package:bourse_agricole_web/ui/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Extension officielle pour adapter l'application aux langues locales (dates, calendriers...)
import 'package:flutter_localizations/flutter_localizations.dart'; 

void main() async {
  // Garantit que les services Flutter sont bien initialisés avant de lancer Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Connexion de l'application à votre base de données Supabase
  await Supabase.initialize(
    url: 'https://djrywiufzvpuybkzqlow.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcnl3aXVmenZwdXlia3pxbG93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjU5NTIsImV4cCI6MjA4MDk0MTk1Mn0.1I1qDV59WJrQ-dNHRLgASxlB2kMQxm5ZXzZTGQKI1Gw',
  );

  // Lancement de l'application principale
  runApp(const BourseAgricoleApp());
}

class BourseAgricoleApp extends StatelessWidget {
  const BourseAgricoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAN ITURI',
      // Supprime le petit bandeau rouge "DEBUG" en haut à droite de l'écran
      debugShowCheckedModeBanner: false,
      
      // Configuration pour traduire l'application (indispensable pour afficher les sélecteurs de date en français)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Traductions des composants de base (Material Design)
        GlobalWidgetsLocalizations.delegate,  // Traductions des textes directionnels (gauche/droite)
        GlobalCupertinoLocalizations.delegate, // Traductions pour le style iOS (Apple)
      ],
      // Déclaration des langues prises en charge par l'application
      supportedLocales: const [
        Locale('fr', 'FR'), // Langue principale : Français
        Locale('en', 'US'), // Langue secondaire : Anglais
      ],

      // Personnalisation graphique générale de l'application (Thème)
      theme: ThemeData(
        useMaterial3: true, // Activation des composants graphiques modernes de Flutter
        primaryColor: const Color(0xFF1B5E20), // Vert foncé pour l'identité agricole
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Génère automatiquement des nuances de couleurs assorties
        ),
      ),
      
      // Gestion de la navigation et du routage des écrans
      initialRoute: '/', // Point de départ de l'application (ex: Écran d'accueil ou de connexion)
      onGenerateRoute: AppRouter.generateRoute, // Délègue la création des routes à votre gestionnaire personnalisé
    );
  }
}