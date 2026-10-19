import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _error;
  String _audience = 'Mes abonnés'; // Mes abonnés, Public, Proches

  // Position du texte (si on ajoute la fonctionnalité texte plus tard)
  Offset _textPosition = const Offset(100, 300);
  String _overlayText = '';

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    }
  }

  Future<void> _publishStory() async {
    if (_imageBytes == null) {
      setState(() => _error = 'Choisis une image pour ta story');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Note: pour l'instant on envoie juste l'image, 
    // le backend gère déjà le caption (qu'on utilisera pour le texte plus tard)
    final result = await StoryService.createStory(
      imageBytes: _imageBytes!,
      imageName: _pickedImage?.name ?? 'story.jpg',
      caption: _overlayText, 
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _error = result['error'] ?? 'Erreur';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si pas d'image, on affiche un écran noir avec un bouton pour choisir
    if (_imageBytes == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera_back, size: 80, color: Colors.white.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'Choisis une photo pour ta story',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brightGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Ouvrir la galerie', style: TextStyle(fontSize: 16)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    // Sinon, on affiche le studio de création immersif
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── LA PHOTO (FOND) ───
          Image.memory(
            _imageBytes!,
            fit: BoxFit.cover, // Remplit tout l'écran
          ),

          // ─── ASSOMBRISSEMENT HAUT/BAS POUR LISIBILITÉ ───
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // ─── BARRE SUPÉRIEURE ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Retour
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                  
                  // Titre
                  const Text(
                    'Nouvelle story',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  
                  // Options / Brouillon (placeholder)
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── OUTILS SUR LE CÔTÉ DROIT (Texte, Sticker, etc.) ───
          Positioned(
            right: 16,
            top: 120,
            child: Column(
              children: [
                _buildSideTool(Icons.text_fields, 'Texte', () {
                  // Plus tard : ajouter du texte
                }),
                const SizedBox(height: 20),
                _buildSideTool(Icons.emoji_emotions_outlined, 'Stickers', () {}),
                const SizedBox(height: 20),
                _buildSideTool(Icons.brush_outlined, 'Dessin', () {}),
                const SizedBox(height: 20),
                _buildSideTool(Icons.filter_vintage_outlined, 'Filtres', () {}),
              ],
            ),
          ),

          // ─── TEXTE SUPERPOSÉ (si l'utilisateur en ajoute plus tard) ───
          if (_overlayText.isNotEmpty)
            Positioned(
              left: 50,
              top: 200,
              child: Text(
                _overlayText,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 5)]),
              ),
            ),

          // ─── ZONE INFÉRIEURE (Audience + Boutons) ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Choix de l'audience
                    GestureDetector(
                      onTap: () {
                        // Plus tard : menu de choix d'audience
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(_audience, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Boutons d'action
                    Row(
                      children: [
                        // Bouton "Votre story" (secondaire)
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: AppTheme.brightGreen),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_circle_outline, color: AppTheme.brightGreen, size: 20),
                                  SizedBox(width: 6),
                                  Text('Votre story', style: TextStyle(color: AppTheme.brightGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),

                        // Bouton "Partager" (principal, dégradé)
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _publishStory,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppTheme.storyGradient,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.brightGreen.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Partager', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)),
                                          SizedBox(width: 6),
                                          Icon(Icons.send, color: Colors.black, size: 18),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les outils sur le côté
  Widget _buildSideTool(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}