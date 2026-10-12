import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/user.dart';
import 'api_config.dart';
import 'auth_service.dart';

class UserService {
  /// Récupère le profil public d'un utilisateur
  static Future<Map<String, dynamic>> getUser(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse(ApiConfig.userDetail(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data),
          'isFollowing': data['is_following'] ?? false,
          'isMe': data['is_me'] ?? false,
        };
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Suit / Ne suit plus un utilisateur
  static Future<Map<String, dynamic>> toggleFollow(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.post(
        Uri.parse(ApiConfig.userFollow(userId)),
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

  /// Récupère les posts d'un utilisateur
  static Future<Map<String, dynamic>> getUserPosts(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse(ApiConfig.userPosts(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final posts = data.map((json) => Post.fromJson(json)).toList();
        return {'success': true, 'posts': posts};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Liste des abonnés d'un utilisateur
  static Future<Map<String, dynamic>> getFollowers(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse(ApiConfig.userFollowers(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return {'success': true, 'users': users};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Liste des abonnements d'un utilisateur
  static Future<Map<String, dynamic>> getFollowing(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse(ApiConfig.userFollowing(userId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        return {'success': true, 'users': users};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }
}