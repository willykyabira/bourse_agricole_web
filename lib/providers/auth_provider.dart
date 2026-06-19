// Gestion d'état Auth
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_client.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _user = BanSupabase.client.auth.currentUser;
  }

  // Fonction de connexion pour le staff
  Future<void> login(String email, String password) async {
    await BanSupabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    _user = BanSupabase.client.auth.currentUser;
    notifyListeners();
  }

  Future<void> logout() async {
    await BanSupabase.client.auth.signOut();
    _user = null;
    notifyListeners();
  }
}