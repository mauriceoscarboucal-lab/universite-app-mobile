import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';

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

  // Texte superposé
  String _overlayText = '';
  String _caption = '';     // <-- NOUVEAU : La légende
  Offset _textPosition = const Offset(50, 300);

  // Clé pour capturer l'image + le texte
  final GlobalKey _repaintKey = GlobalKey();

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

  Future<void> _addText() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Ajouter du texte', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ton texte...',
            hintStyle: TextStyle(color: AppTheme.textGrey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.borderGreen)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.brightGreen)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brightGreen),
            child: const Text('Placer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _overlayText = result);
    }
  }

    Future<void> _addCaption() async {
    final TextEditingController controller = TextEditingController(text: _caption);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Ajouter une légende', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 150,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Écris une légende pour ta story...',
            hintStyle: TextStyle(color: AppTheme.textGrey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.borderGreen)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.brightGreen)),
            counterStyle: TextStyle(color: AppTheme.textGrey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brightGreen),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _caption = result);
    }
  }

  // 📸 Capturer le rendu visuel (image + texte) en une seule image
  Future<Uint8List?> _captureWidget() async {
    try {
      RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
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

    Uint8List? finalImageBytes = _imageBytes;

    // Si l'utilisateur a ajouté du texte, on grave l'image
    if (_overlayText.isNotEmpty) {
      finalImageBytes = await _captureWidget();
    }

    if (finalImageBytes == null) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur de capture de l\'image';
      });
      return;
    }

    final result = await StoryService.createStory(
      imageBytes: finalImageBytes,
      imageName: 'story.jpg',
      caption: _caption, // <-- ON ENVOIE LA LÉGENDE SAISIE
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
    if (_imageBytes == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Choisis une photo', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brightGreen),
                child: const Text('Ouvrir la galerie'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─── ZONE IMAGE (Gravure) ───
          Positioned.fill(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                  if (_overlayText.isNotEmpty)
                    Positioned(
                      left: _textPosition.dx,
                      top: _textPosition.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() => _textPosition += details.delta);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.white.withOpacity(0.9),
                          child: Text(
                            _overlayText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── BARRE SUPÉRIEURE (Fixée en haut) ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      ),
                    ),
                    const Text(
                      'Nouvelle story',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── OUTILS (Texte, Stickers, etc.) ───
          Positioned(
            right: 16,
            top: 120,
            child: Column(
              children: [
                _buildSideTool(Icons.text_fields, 'Texte', _addText),
                const SizedBox(height: 20),
                _buildSideTool(Icons.emoji_emotions_outlined, 'Stickers', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible 🚧')));
                }),
                const SizedBox(height: 20),
                _buildSideTool(Icons.brush_outlined, 'Dessin', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible 🚧')));
                }),
                const SizedBox(height: 20),
                _buildSideTool(Icons.filter_vintage_outlined, 'Filtres', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible 🚧')));
                }),
              ],
            ),
          ),

          // ─── BOUTONS DU BAS ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Bouton "Ajouter une légende"
                    Expanded(
                      child: GestureDetector(
                        onTap: _addCaption, // <-- APPELER LA SAISIE DE LÉGENDE
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
                              children: [
                                const Icon(Icons.edit_note, color: AppTheme.brightGreen, size: 22),
                                const SizedBox(width: 6),
                                Text(
                                  _caption.isEmpty ? 'Légende' : 'Modifier légende',
                                  style: const TextStyle(color: AppTheme.brightGreen, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton "Partager"
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _publishStory,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppTheme.storyGradient,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(color: AppTheme.brightGreen.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
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
              ),
            ),
          ),

          // Message d'erreur
          if (_error != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red.withOpacity(0.8),
                child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSideTool(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}