import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/story.dart';
import 'api_config.dart';
import 'auth_service.dart';

class StoryService {
  /// Récupère la liste des stories groupées par auteur
  static Future<Map<String, dynamic>> getStories() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse(ApiConfig.stories),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final groups = data
            .map((json) => StoryGroup.fromJson(json))
            .toList();
        return {'success': true, 'groups': groups};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Publie une nouvelle story
  static Future<Map<String, dynamic>> createStory({
    required Uint8List imageBytes,
    required String imageName,
    String caption = '',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final uri = Uri.parse(ApiConfig.stories);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['caption'] = caption;

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
        ),
      );

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

  /// Supprime une story
  static Future<Map<String, dynamic>> deleteStory(int storyId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.delete(
        Uri.parse(ApiConfig.storyDetail(storyId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }
}