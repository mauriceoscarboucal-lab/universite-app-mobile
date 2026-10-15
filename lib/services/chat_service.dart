import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ChatService {
  /// Liste de mes conversations
  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse(ApiConfig.conversations),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final conversations =
            data.map((j) => Conversation.fromJson(j)).toList();
        return {'success': true, 'conversations': conversations};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Crée (ou récupère) une conversation avec un utilisateur
  static Future<Map<String, dynamic>> startConversation(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.post(
        Uri.parse(ApiConfig.conversations),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'conversation': Conversation.fromJson(jsonDecode(response.body)),
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Récupère les messages d'une conversation
    static Future<Map<String, dynamic>> getMessages(
    int conversationId, {
    bool markRead = false,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final uri = Uri.parse(ApiConfig.messages(conversationId))
          .replace(queryParameters: markRead ? {'read': '1'} : null);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final messages = data.map((j) => Message.fromJson(j)).toList();
        return {'success': true, 'messages': messages};
      }
      return {'success': false, 'error': 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Envoie un message dans une conversation
  static Future<Map<String, dynamic>> sendMessage(
    int conversationId,
    String content,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.post(
        Uri.parse(ApiConfig.messages(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': Message.fromJson(jsonDecode(response.body)),
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

    /// Récupère le nombre total de messages non lus
  static Future<int> getUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse(ApiConfig.unreadCount),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

    /// Supprime un message
  /// scope = 'me' (défaut) ou 'all'
  static Future<Map<String, dynamic>> deleteMessage(
    int messageId, {
    String scope = 'me',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final uri = Uri.parse('${ApiConfig.baseUrl}/chat/messages/$messageId/')
          .replace(queryParameters: {'scope': scope});

      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }

  /// Modifie un message
  static Future<Map<String, dynamic>> editMessage(
    int messageId,
    String newContent,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/chat/messages/$messageId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': Message.fromJson(jsonDecode(response.body)),
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Erreur'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau : $e'};
    }
  }
}

