import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';

/// Classe responsable de l'initialisation
/// et de l'accès au client Supabase.
class BanSupabase {
  /// Retourne le client Supabase utilisé dans toute l'application.
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialise la connexion avec Supabase.
  static Future<void> init() async {
    await Supabase.initialize(
      url: BanConstants.supabaseUrl,
      anonKey: BanConstants.supabaseAnonKey,
    );
  }
}
