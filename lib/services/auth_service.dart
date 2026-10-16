import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_config.dart';
import 'dart:typed_data';

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConfig.tokenKey, data['access']);
        await prefs.setString(ApiConfig.refreshKey, data['refresh']);

        // Décode le JWT pour récupérer l'ID utilisateur
        try {
          final parts = data['access'].split('.');
          if (parts.length == 3) {
            final payload = utf8.decode(
              base64Url.decode(base64Url.normalize(parts[1])),
            );
            final payloadData = jsonDecode(payload);
            final userId = payloadData['user_id'];
            if (userId != null) {
              await prefs.setInt('user_id', int.parse(userId.toString()));
            }
          }
        } catch (e) {
          print('Erreur décodage JWT: $e');
        }

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Email ou mot de passe incorrect'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Récupère l'ID de l'utilisateur connecté (0 si non connecté)
  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  /// Inscription d'un nouvel étudiant
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
    String firstName = '',
    String lastName = '',
    String filiere = '',
    String niveau = '',
    String dateOfBirth = '',
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
          'first_name': firstName,
          'last_name': lastName,
          'filiere': filiere,
          'niveau': niveau,
          'date_of_birth': dateOfBirth.isEmpty ? null : dateOfBirth,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
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
    await prefs.remove('user_id');
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
        return {
          'success': true,
          'user': User.fromJson(jsonDecode(response.body)),
        };
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Met à jour le profil
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
        return {
          'success': true,
          'user': User.fromJson(jsonDecode(response.body)),
        };
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

    /// Envoie un code de vérification par email
  static Future<Map<String, dynamic>> sendVerificationCode() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.post(
        Uri.parse(ApiConfig.sendVerification),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Vérifie le code saisi
  static Future<Map<String, dynamic>> verifyEmail(String code) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.post(
        Uri.parse(ApiConfig.verifyEmail),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Marque le profil comme complété (avec bio + photo optionnelle)
    static Future<Map<String, dynamic>> completeProfile({
    String bio = '',
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final uri = Uri.parse(ApiConfig.completeProfile);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['bio'] = bio;

      // 📸 Image (via bytes pour compatibilité web + mobile)
      if (photoBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photoBytes,
            filename: photoName ?? 'photo.jpg',
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }
}