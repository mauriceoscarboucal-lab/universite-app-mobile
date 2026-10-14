class Story {
  final int id;
  final int author;
  final String authorUsername;
  final String? authorPhoto;
  final String image;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewsCount;
  final bool isViewed;

  Story({
    required this.id,
    required this.author,
    required this.authorUsername,
    this.authorPhoto,
    required this.image,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewsCount = 0,
    this.isViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      author: json['author'],
      authorUsername: json['author_username'] ?? '',
      authorPhoto: json['author_photo'],
      image: json['image'] ?? '',
      caption: json['caption'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      viewsCount: json['views_count'] ?? 0,
      isViewed: json['is_viewed'] ?? false,
    );
  }
}

/// Groupe de stories d'un même auteur
class StoryGroup {
  final int authorId;
  final String authorUsername;
  final String? authorPhoto;
  final List<Story> stories;
  final bool allViewed;

  StoryGroup({
    required this.authorId,
    required this.authorUsername,
    this.authorPhoto,
    required this.stories,
    this.allViewed = false,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    return StoryGroup(
      authorId: json['author_id'],
      authorUsername: json['author_username'] ?? '',
      authorPhoto: json['author_photo'],
      stories: (json['stories'] as List)
          .map((s) => Story.fromJson(s))
          .toList(),
      allViewed: json['all_viewed'] ?? false,
    );
  }
}

/// Représente un utilisateur qui a vu une story
class StoryViewer {
  final int id;
  final int userId;
  final String username;
  final String filiere;
  final String niveau;
  final String? photo;
  final DateTime viewedAt;

  StoryViewer({
    required this.id,
    required this.userId,
    required this.username,
    required this.filiere,
    required this.niveau,
    this.photo,
    required this.viewedAt,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'] ?? '',
      filiere: json['filiere'] ?? '',
      niveau: json['niveau'] ?? '',
      photo: json['photo'],
      viewedAt: DateTime.parse(json['viewed_at']),
    );
  }
}