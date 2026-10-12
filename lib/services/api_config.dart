/// Configuration de l'API Django
class ApiConfig {
  // Adresse de ton backend Django
  static const String baseUrl = 'http://192.168.1.3:8000/api';

  // Endpoints
  static const String register = '$baseUrl/auth/register/';
  static const String login = '$baseUrl/auth/login/';
  static const String me = '$baseUrl/auth/me/';
  static const String posts = '$baseUrl/posts/';

  // Clés de stockage local
  static const String tokenKey = 'access_token';
  static const String refreshKey = 'refresh_token';
}