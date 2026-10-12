class Post {
  final int id;
  final int author;
  final String authorUsername;
  final String? authorPhoto;
  final String content;
  final String? image;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    required this.authorUsername,
    this.authorPhoto,
    required this.content,
    this.image,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  /// Crée un Post à partir du JSON renvoyé par l'API Django
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: json['author'],
      authorUsername: json['author_username'] ?? '',
      authorPhoto: json['author_photo'],
      content: json['content'] ?? '',
      image: json['image'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}