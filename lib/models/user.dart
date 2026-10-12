class User {
  final int id;
  final String username;
  final String email;
  final String filiere;
  final String niveau;
  final String? photo;
  final String bio;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.filiere,
    required this.niveau,
    this.photo,
    required this.bio,
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
    );
  }
}