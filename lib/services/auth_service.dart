import '../models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Service qui gère l'authentification (login, register, token)
class AuthService {
  /// Connexion : envoie email + password, stocke le token
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Sauvegarde les tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConfig.tokenKey, data['access']);
        await prefs.setString(ApiConfig.refreshKey, data['refresh']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Email ou mot de passe incorrect'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Inscription d'un nouvel étudiant
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
    String filiere = '',
    String niveau = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'password2': password2,
          'filiere': filiere,
          'niveau': niveau,
        }),
      );

      if (response.statusCode == 201) {
  return {'success': true, 'data': jsonDecode(response.body)};
} else {
  // Affiche le vrai message d'erreur de Django
  final errorBody = jsonDecode(response.body);
  String errorMsg = 'Erreur inconnue';
  if (errorBody is Map) {
    errorMsg = errorBody.entries
        .map((e) => '${e.key} : ${e.value}')
        .join('\n');
  }
  return {'success': false, 'error': errorMsg};
}
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Récupère le token stocké (ou null si pas connecté)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  /// Déconnexion : efface les tokens
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.refreshKey);
  }

  /// Est-ce que l'utilisateur est connecté ?
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

    /// Récupère le profil de l'utilisateur connecté
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'user': User.fromJson(jsonDecode(response.body))};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Met à jour le profil (username, filière, niveau, bio)
  static Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String filiere,
    required String niveau,
    required String bio,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.put(
        Uri.parse(ApiConfig.me),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'username': username,
          'filiere': filiere,
          'niveau': niveau,
          'bio': bio,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'user': User.fromJson(jsonDecode(response.body))};
      } else {
        final errorBody = jsonDecode(response.body);
        String errorMsg = 'Erreur ${response.statusCode}';
        if (errorBody is Map) {
          errorMsg = errorBody.entries
              .map((e) => '${e.key} : ${e.value}')
              .join('\n');
        }
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }
}