/// Configuration de l'API Django
class ApiConfig {
  // Adresse de ton backend Django
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Endpoints auth
  static const String register = '$baseUrl/auth/register/';
  static const String login = '$baseUrl/auth/login/';
  static const String me = '$baseUrl/auth/me/';
  static const String posts = '$baseUrl/posts/';
  static const String stories = '$baseUrl/stories/';
  static const String myStories = '$baseUrl/stories/mine/';

  // Endpoints utilisateurs
  static String userDetail(int userId) => '$baseUrl/auth/users/$userId/';
  static String userFollow(int userId) => '$baseUrl/auth/users/$userId/follow/';
  static String userPosts(int userId) => '$baseUrl/auth/users/$userId/posts/';
  static String userFollowers(int userId) => '$baseUrl/auth/users/$userId/followers/';
  static String userFollowing(int userId) => '$baseUrl/auth/users/$userId/following/';
  static String storyDetail(int id) => '$baseUrl/stories/$id/';

  // Clés de stockage local
  static const String tokenKey = 'access_token';
  static const String refreshKey = 'refresh_token';

    /// Transforme une URL relative (ex: /media/stories/x.jpg) en URL complète
  static String fullUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return '';
    if (relativeUrl.startsWith('http')) return relativeUrl;
    // On retire '/api' de baseUrl pour avoir la racine
    final root = baseUrl.replaceAll('/api', '');
    return '$root$relativeUrl';
  }
}