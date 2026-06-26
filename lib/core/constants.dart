/// Classe contenant les constantes utilisées dans toute l'application.
class BanConstants {
  // ==========================
  // Configuration Supabase
  // ==========================

  /// Adresse du projet Supabase.
  static const String supabaseUrl =
      'https://djrywiufzvpuybkzqlow.supabase.co';

  /// Clé publique (Anon Key) permettant à l'application
  /// de communiquer avec Supabase.
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsImRyZiI6ImRqcnl3aXVmenZwdXlia3pxbG93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjU5NTIsImV4cCI6MjA4MDk0MTk1Mn0.1I1qDV59WJrQ-dNHRLgASxlB2kMQxm5ZXzZTGQKI1Gw';

  // ==========================
  // Noms des tables Supabase
  // ==========================

  /// Table contenant les produits agricoles.
  static const String tableProduits = 'produits';

  /// Table contenant les informations des utilisateurs.
  static const String tableProfils = 'profiles';

  /// Table contenant les transactions.
  static const String tableTransactions = 'transactions';
}