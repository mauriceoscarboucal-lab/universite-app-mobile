class User {
  final int id;
  final String username;
  final String email;
  final String filiere;
  final String niveau;
  final String? photo;
  final String bio;
  final int followersCount;
  final int followingCount;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.filiere,
    required this.niveau,
    this.photo,
    required this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      filiere: json['filiere'] ?? '',
      niveau: json['niveau'] ?? '',
      photo: json['photo'],
      bio: json['bio'] ?? '',
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }
}