import 'package:flutter/material.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Publication', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // On affiche la carte du post en grand
            PostCard(
              post: post,
              onRefresh: () {
                // Si on rafraîchit depuis l'intérieur, on revient en arrière
                // (ou on pourrait recharger le post)
                Navigator.pop(context);
              },
            ),
            // Un petit espace en bas
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}