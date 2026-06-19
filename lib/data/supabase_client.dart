// Initialisation du client Supabase
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class BanSupabase {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: BanConstants.supabaseUrl,
      anonKey: BanConstants.supabaseAnonKey,
    );
  }
}