import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class NotificationService {
  static Future<int> getUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;
      final response = await http.get(Uri.parse(ApiConfig.notifications), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.where((n) => !n['is_read']).length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'success': false};
      final response = await http.get(Uri.parse(ApiConfig.notifications), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<void> markAllAsRead() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await http.post(Uri.parse(ApiConfig.notifications), headers: {'Authorization': 'Bearer $token'});
    } catch (e) {}
  }
}