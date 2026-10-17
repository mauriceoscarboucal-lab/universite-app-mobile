import 'package:flutter/material.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final String? photo;
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
    final bg = backgroundColor ?? AppTheme.brightGreen;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    // Si pas de photo → initiale
    if (photo == null || photo!.isEmpty) {
      return _buildInitialAvatar(bg, initial);
    }

    // Sinon → photo avec fallback si erreur
    final url = photo!.startsWith('http') ? photo! : ApiConfig.fullUrl(photo!);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Si l'image ne charge pas → affiche l'initiale
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialAvatar(bg, initial);
          },
          // Pendant le chargement → affiche l'initiale
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitialAvatar(bg, initial);
          },
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(Color bg, String initial) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}