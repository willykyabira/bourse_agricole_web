import 'package:bourse_agricole_web/ui/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// 1. IMPORT IMPORTANT POUR LES DATES
import 'package:flutter_localizations/flutter_localizations.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase
  await Supabase.initialize(
    url: 'https://djrywiufzvpuybkzqlow.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcnl3aXVmenZwdXlia3pxbG93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjU5NTIsImV4cCI6MjA4MDk0MTk1Mn0.1I1qDV59WJrQ-dNHRLgASxlB2kMQxm5ZXzZTGQKI1Gw',
  );

  runApp(const BourseAgricoleApp());
}

class BourseAgricoleApp extends StatelessWidget {
  const BourseAgricoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAN ITURI',
      debugShowCheckedModeBanner: false,
      
      // 2. CONFIGURATION DES LOCALISATIONS (Pour éviter l'écran rouge)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français pour Ituri/RDC
        Locale('en', 'US'),
      ],
      // --------------------------------------------------------

      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1B5E20),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
      ),
      initialRoute: '/', 
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}