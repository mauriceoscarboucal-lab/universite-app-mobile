import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'package:image_cropper/image_cropper.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

    Future<void> _pickImage() async {
    try {
      // 1️⃣ Choisir une image
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      // 2️⃣ Ouvrir l'outil de recadrage (carré 1:1 pour avatar)
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer ma photo',
            toolbarColor: AppTheme.green,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Recadrer ma photo',
            aspectRatioLockEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              width: 500,
              height: 500,
            ),
          ),
        ],
      );

      if (cropped == null) return;

      // 3️⃣ Lire les bytes de l'image recadrée
      final bytes = await cropped.readAsBytes();

      setState(() {
        _pickedImage = XFile(cropped.path);
        _imageBytes = bytes;
      });
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    }
  }

  Future<void> _finish() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.completeProfile(
      bio: _bioController.text.trim(),
      photoBytes: _imageBytes,
      photoName: _pickedImage?.name,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bienvenue sur Baobab ! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _error = result['error'] ?? 'Erreur';
      });
    }
  }

  void _skip() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.gradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 120,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Bienvenue sur Baobab 🌳',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Complète ton profil pour commencer',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // Carte
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFDF5),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Photo de profil
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[100],
                                  border: Border.all(
                                    color: AppTheme.green,
                                    width: 3,
                                  ),
                                  image: _imageBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(_imageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _imageBytes == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    gradient: AppTheme.gradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _imageBytes == null
                              ? 'Ajouter une photo'
                              : 'Changer la photo',
                          style: const TextStyle(
                            color: AppTheme.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bio
                        TextField(
                          controller: _bioController,
                          maxLines: 4,
                          maxLength: 200,
                          decoration: InputDecoration(
                            labelText: 'Bio (optionnel)',
                            hintText: 'Parle un peu de toi...',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.info_outline,
                                  color: AppTheme.green),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.green,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            alignLabelWithHint: true,
                          ),
                        ),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Bouton Terminer
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _finish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Terminer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Bouton Passer
                        TextButton(
                          onPressed: _isLoading ? null : _skip,
                          child: const Text(
                            'Passer pour le moment',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}