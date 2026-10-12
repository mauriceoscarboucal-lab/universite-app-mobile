class Comment {
  final int id;
  final int author;
  final String authorUsername;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.author,
    required this.authorUsername,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      author: json['author'],
      authorUsername: json['author_username'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}