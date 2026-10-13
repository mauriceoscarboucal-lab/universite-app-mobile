class Post {
  final int id;
  final int author;
  final String authorUsername;
  final String? authorPhoto;
  final String content;
  final String? image;
  final List<String> images;
  final String backgroundColor;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isFollowingAuthor;
  final bool isMyPost;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    required this.authorUsername,
    this.authorPhoto,
    required this.content,
    this.image,
    this.images = const [],
    this.backgroundColor = '',
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isFollowingAuthor,
    required this.isMyPost,
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
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      backgroundColor: json['background_color'] ?? '',    // <-- AJOUTE
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isFollowingAuthor: json['is_following_author'] ?? false,
      isMyPost: json['is_my_post'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}