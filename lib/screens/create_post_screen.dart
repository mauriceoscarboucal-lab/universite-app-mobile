import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _hashtagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _pickedImages = [];
  List<Uint8List> _imageBytesList = [];
  List<String> _hashtags = [];
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // ⚠️ On utilise les minuscules pour correspondre au backend
  String _audience = 'public'; 

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final result = await AuthService.getProfile();
    if (mounted && result['success'] == true) {
      setState(() => _currentUser = result['user']);
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 70,
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

  void _addHashtag(String tag) {
    String cleanTag = tag.trim();
    if (cleanTag.isEmpty) return;
    if (cleanTag.startsWith('#')) cleanTag = cleanTag.substring(1);
    
    if (!_hashtags.contains(cleanTag)) {
      setState(() {
        _hashtags.add(cleanTag);
        _hashtagController.clear();
      });
    }
  }

  void _removeHashtag(String tag) {
    setState(() => _hashtags.remove(tag));
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

    final hashtagsString = _hashtags.map((t) => '#$t').join(' ');
    final finalContent = content + (hashtagsString.isNotEmpty ? '\n\n$hashtagsString' : '');

    final result = await PostService.createPost(
      finalContent,
      multipleImages: _imageBytesList.isEmpty ? null : _imageBytesList,
      multipleNames: _imageBytesList.isEmpty ? null : _pickedImages.map((e) => e.name).toList(),
      backgroundColor: '',
      audience: _audience, // <-- Envoie l'audience
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
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Créer une publication',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset('assets/images/logo.png', height: 28, errorBuilder: (_, __, ___) => const SizedBox()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── AUTEUR + AUDIENCE ───
                  Row(
                    children: [
                      UserAvatar(
                        username: _currentUser?.username ?? '',
                        photo: _currentUser?.photo,
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUser?.username ?? 'Chargement...',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '@${_currentUser?.username ?? ''}',
                              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderGreen),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _audience, // <-- Doit correspondre à une valeur des items
                            dropdownColor: AppTheme.darkCard,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                            items: const [
                              DropdownMenuItem(
                                value: 'public', 
                                child: Row(
                                  children: [
                                    Icon(Icons.public, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Public'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'followers', 
                                child: Row(
                                  children: [
                                    Icon(Icons.people, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Abonnés'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'private', 
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_outline, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Moi uniquement'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (newValue) {
                              if (newValue != null) setState(() => _audience = newValue);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),

                  // ─── ZONE DE TEXTE ───
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
                      minLines: 5,
                      maxLength: 500,
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

                  // ─── APERÇU DES PHOTOS ───
                  if (_imageBytesList.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _imageBytesList.length + (_imageBytesList.length < 4 ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _imageBytesList.length) {
                          return GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.darkCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderGreen),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: AppTheme.brightGreen, size: 32),
                                  SizedBox(height: 4),
                                  Text('Ajouter', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_imageBytesList[i], width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            if (i == 0 && _imageBytesList.length > 1)
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                  child: Text('1/${_imageBytesList.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // ─── OUTILS (Photo / Live / Sondage) ───
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGreen),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildToolItem(Icons.photo_library_outlined, 'Photo/vidéo', _pickImages),
                        _buildToolItem(Icons.videocam_outlined, 'Vidéo en direct', () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible 🚧')));
                        }),
                        _buildToolItem(Icons.poll_outlined, 'Sondage', () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible 🚧')));
                        }),
                        _buildToolItem(Icons.more_horiz, 'Plus', () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plus d\'options bientôt 🚧')));
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── HASHTAGS ───
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGreen),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tag, color: AppTheme.brightGreen, size: 20),
                            SizedBox(width: 8),
                            Text('Ajouter des hashtags', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _hashtagController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: _addHashtag,
                          decoration: InputDecoration(
                            hintText: 'Ex: USSEIN',
                            hintStyle: const TextStyle(color: AppTheme.textGrey),
                            isDense: true,
                            filled: true,
                            fillColor: AppTheme.darkBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_circle, color: AppTheme.brightGreen),
                              onPressed: () => _addHashtag(_hashtagController.text),
                            ),
                          ),
                        ),
                        if (_hashtags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _hashtags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.brightGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.brightGreen),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('#$tag', style: const TextStyle(color: AppTheme.brightGreen, fontSize: 12)),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _removeHashtag(tag),
                                      child: const Icon(Icons.close, color: AppTheme.brightGreen, size: 14),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── LOCALISATION & QUI PEUT VOIR ───
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGreen),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          tileColor: Colors.transparent,
                          leading: const Icon(Icons.location_on_outlined, color: AppTheme.brightGreen),
                          title: const Text('Ajouter une localisation', style: TextStyle(color: Colors.white, fontSize: 14)),
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: AppTheme.borderGreen),
                        ListTile(
                          tileColor: Colors.transparent,
                          leading: const Icon(Icons.visibility_outlined, color: AppTheme.brightGreen),
                          title: const Text('Qui peut voir cette publication ?', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(
                            _audience == 'public' ? 'Public' : (_audience == 'followers' ? 'Abonnés' : 'Moi uniquement'), 
                            style: const TextStyle(color: AppTheme.goldYellow, fontSize: 12)
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ─── BOUTON PUBLIER (Dégradé Jaune/Vert) ───
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
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppTheme.storyGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brightGreen.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: AppTheme.darkBg, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Publier', style: TextStyle(color: AppTheme.darkBg, fontSize: 18, fontWeight: FontWeight.w900)),
                                SizedBox(width: 8),
                                Icon(Icons.send, color: AppTheme.darkBg, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppTheme.brightGreen, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
        ],
      ),
    );
  }
}