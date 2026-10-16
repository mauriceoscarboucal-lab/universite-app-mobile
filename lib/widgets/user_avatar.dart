import 'package:flutter/material.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

/// 🌳 Avatar réutilisable partout : affiche la photo si dispo, sinon l'initiale
class UserAvatar extends StatelessWidget {
  final String username;
  final String? photo; // URL relative ou complète
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.username,
    this.photo,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.green;

    // Si pas de photo → initiale
    if (photo == null || photo!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      );
    }

    // Sinon → photo
    final url = photo!.startsWith('http')
        ? photo!
        : ApiConfig.fullUrl(photo!);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
    );
  }
}