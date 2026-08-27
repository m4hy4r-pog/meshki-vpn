// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _api;
  
  AuthService(this._api);

  Future<bool> login(String username, String password) async {
    final user = await _api.login(username, password);
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password); // Consider encrypting this
      await prefs.setString('user_data', jsonEncode(user)); // Add dart:convert import
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData)); // Add dart:convert import
    }
    return null;
  }

  Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('username');
    final p = prefs.getString('password');
    if (u != null && p != null) return {'username': u, 'password': p};
    return null;
  }
}
