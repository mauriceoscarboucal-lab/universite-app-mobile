import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/comment.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class PostService {
  /// Récupère la liste des posts depuis Django
  static Future<Map<String, dynamic>> getPosts() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'error': 'Non connecté'};
      }

      final response = await http.get(
        Uri.parse(ApiConfig.posts),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final posts = data.map((json) => Post.fromJson(json)).toList();
        return {'success': true, 'posts': posts};
      } else {
        return {'success': false, 'error': 'Erreur ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Like / Unlike un post
  static Future<Map<String, dynamic>> toggleLike(int postId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false};

      final response = await http.post(
        Uri.parse('${ApiConfig.posts}$postId/like/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }
      /// Crée un nouveau post avec ou sans image
    static Future<Map<String, dynamic>> createPost(
    String content, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      // On prépare la requête multipart (obligatoire pour envoyer un fichier)
      final uri = Uri.parse(ApiConfig.posts);
      final request = http.MultipartRequest('POST', uri);

      // Header d'autorisation
      request.headers['Authorization'] = 'Bearer $token';

      // Champs texte
      request.fields['content'] = content;

            // Si une image est fournie → on l'ajoute
      if (imageBytes != null) {
        // Cas Web (bytes)
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: imageName ?? 'image.jpg',
          ),
        );
      }

      // Envoi
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
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
    /// Récupère les commentaires d'un post
  static Future<Map<String, dynamic>> getComments(int postId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse('${ApiConfig.posts}$postId/comments/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final comments = data.map((json) => Comment.fromJson(json)).toList();
        return {'success': true, 'comments': comments};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Ajoute un commentaire à un post
  static Future<Map<String, dynamic>> addComment(int postId, String content) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.post(
        Uri.parse('${ApiConfig.posts}$postId/comments/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
  return {'success': true, 'data': jsonDecode(response.body)};
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
    /// Récupère un post unique par son ID
  static Future<Map<String, dynamic>> getPostById(int postId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse('${ApiConfig.posts}$postId/'),
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
}