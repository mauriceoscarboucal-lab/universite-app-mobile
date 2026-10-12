class Story {
  final int id;
  final int author;
  final String authorUsername;
  final String? authorPhoto;
  final String image;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;

  Story({
    required this.id,
    required this.author,
    required this.authorUsername,
    this.authorPhoto,
    required this.image,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
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
    );
  }
}

/// Groupe de stories d'un même auteur
class StoryGroup {
  final int authorId;
  final String authorUsername;
  final String? authorPhoto;
  final List<Story> stories;

  StoryGroup({
    required this.authorId,
    required this.authorUsername,
    this.authorPhoto,
    required this.stories,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    return StoryGroup(
      authorId: json['author_id'],
      authorUsername: json['author_username'] ?? '',
      authorPhoto: json['author_photo'],
      stories: (json['stories'] as List)
          .map((s) => Story.fromJson(s))
          .toList(),
    );
  }
}