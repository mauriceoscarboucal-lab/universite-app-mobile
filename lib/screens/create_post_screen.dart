import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // 📸 Image choisie par l'utilisateur
  XFile? _pickedImage;
Uint8List? _imageBytes;    // <-- pour le web
  final ImagePicker _imagePicker = ImagePicker();

  /// Ouvre la galerie pour choisir une image
  Future<void> _pickImage() async {
  try {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      // En web, on lit directement les bytes
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = image;
        _imageBytes = bytes;
      });
    }
  } catch (e) {
    setState(() => _error = 'Erreur lors du choix : $e');
  }
}

  Future<void> _publish() async {
  final content = _contentController.text.trim();

  if (content.isEmpty && _pickedImage == null) {
    setState(() => _error = 'Écris quelque chose ou choisis une image');
    return;
  }

  setState(() {
    _isLoading = true;
    _error = null;
  });

    final result = await PostService.createPost(
    content,
    imageBytes: _imageBytes,
    imageName: _pickedImage?.name,
  );

  if (!mounted) return;

  if (result['success'] == true) {
    Navigator.pop(context, true);
  } else {
    setState(() {
      _isLoading = false;
      _error = result['error'] ?? 'Erreur inconnue';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau post'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
                child: Column(
          children: [
            // Champ de texte
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: 1000,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Partage quelque chose avec tes camarades...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // ─── APERÇU IMAGE ────────────────────────
            if (_pickedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(
                            _pickedImage!.path,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_pickedImage!.path),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _pickedImage = null),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // ─── BOUTON AJOUTER PHOTO ────────────────
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _pickedImage == null
                    ? 'Ajouter une photo'
                    : 'Changer la photo',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message d'erreur
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Bouton publier
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _publish,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Publication...' : 'Publier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}