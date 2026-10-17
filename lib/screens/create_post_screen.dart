import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _pickedImages = [];
  List<Uint8List> _imageBytesList = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 70, // Qualité réduite pour la vitesse
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (images.isNotEmpty) {
        final List<Uint8List> newBytes = [];
        for (var img in images) {
          newBytes.add(await img.readAsBytes());
        }
        setState(() {
          _pickedImages.addAll(images);
          _imageBytesList.addAll(newBytes);
        });
      }
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
      _imageBytesList.removeAt(index);
    });
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _imageBytesList.isEmpty) {
      setState(() => _error = 'Écris quelque chose ou choisis une photo');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await PostService.createPost(
      content,
      multipleImages: _imageBytesList.isEmpty ? null : _imageBytesList,
      multipleNames: _imageBytesList.isEmpty ? null : _pickedImages.map((e) => e.name).toList(),
      backgroundColor: '', // On ne gère plus les fonds de couleur
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
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Nouveau post', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── ZONE DE TEXTE (SANS FOND DE COULEUR) ───
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGreen),
                    ),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: 6,
                      maxLength: 2000,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Quoi de neuf ?',
                        hintStyle: TextStyle(color: AppTheme.textGrey),
                        border: InputBorder.none,
                        counterStyle: TextStyle(color: AppTheme.textGrey),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // ─── GRILLE D'IMAGES ───
                  if (_imageBytesList.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _imageBytesList.length + 1, // +1 pour le bouton Ajouter
                      itemBuilder: (context, i) {
                        if (i == _imageBytesList.length) {
                          return GestureDetector(
                            onTap: _pickedImages.length >= 20 ? null : _pickImages,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.darkCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderGreen),
                              ),
                              child: const Icon(Icons.add, color: AppTheme.brightGreen, size: 40),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _imageBytesList[i],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderGreen),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 40, color: AppTheme.brightGreen),
                            SizedBox(height: 8),
                            Text('Ajouter jusqu\'à 20 photos', style: TextStyle(color: AppTheme.textGrey)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),

          // ─── BOUTON PUBLIER ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.darkBg,
              border: Border(top: BorderSide(color: AppTheme.borderGreen)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brightGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}