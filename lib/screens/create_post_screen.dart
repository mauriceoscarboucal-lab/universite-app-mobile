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

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Onglet Texte
  final _textController = TextEditingController();
  String _selectedColor = '';

    // Onglet Photo
  final _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _pickedImagess = [];
  List<Uint8List> _imageBytesList = [];

  bool _isLoading = false;
  String? _error;

  // 🎨 Couleurs de fond disponibles pour les posts texte
  final List<String> _colors = [
    '',
    '#2979FF',
    '#00C853',
    '#FFD600',
    '#FF6D00',
    '#D50000',
    '#AA00FF',
    '#FF4081',
    '#00B8D4',
    '#37474F',
    '#1A1A1A',
    '#795548',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

    Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;

      final List<Uint8List> bytesList = [];
      for (final img in images) {
        bytesList.add(await img.readAsBytes());
      }

      setState(() {
        _pickedImagess = images;
        _imageBytesList = bytesList;
      });
    } catch (e) {
      setState(() => _error = 'Erreur lors du choix : $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImagess.removeAt(index);
      _imageBytesList.removeAt(index);
    });
  }

  Future<void> _publish() async {
    final isTextTab = _tabController.index == 0;
    final content =
        isTextTab ? _textController.text.trim() : _captionController.text.trim();

    // Vérifications
    if (!isTextTab && _imageBytesList.isEmpty) {
      setState(() => _error = 'Choisis au moins une photo');
      return;
    }
    if (!isTextTab && _imageBytesList.isEmpty) {
      setState(() => _error = 'Choisis au moins une photo');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await PostService.createPost(
      content,
      multipleImages: isTextTab ? null : _imageBytesList,
      multipleNames:
          isTextTab ? null : _pickedImagess.map((e) => e.name).toList(),
      backgroundColor: isTextTab ? _selectedColor : '',
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

  Color _hexToColor(String hex) {
    if (hex.isEmpty) return Colors.white;
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  bool _isDarkColor(String hex) {
    final color = _hexToColor(hex);
    return color.computeLuminance() < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau post'),
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.gradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.text_fields), text: 'Texte'),
            Tab(icon: Icon(Icons.photo_outlined), text: 'Photo'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(),
                _buildPhotoTab(),
              ],
            ),
          ),

          // ─── BOUTON PUBLIER ───────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
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
                      label: Text(
                        _isLoading ? 'Publication...' : 'Publier',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
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
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ONGLET TEXTE (avec fond coloré)
  // ═══════════════════════════════════════════════════════
  Widget _buildTextTab() {
    final bgColor = _hexToColor(_selectedColor);
    final textColor = _selectedColor.isEmpty
        ? Colors.black87
        : (_isDarkColor(_selectedColor) ? Colors.white : Colors.black87);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 220),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: _selectedColor.isEmpty
                  ? Border.all(color: Colors.grey.shade300)
                  : null,
            ),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _textController,
              maxLines: null,
              minLines: 8,
              maxLength: 1000,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Quoi de neuf ?',
                hintStyle: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                counterStyle: TextStyle(
                  color: textColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choisis une couleur de fond',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, i) {
                final color = _colors[i];
                final isSelected = _selectedColor == color;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _hexToColor(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.green
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: _isDarkColor(color)
                                  ? Colors.white
                                  : Colors.black87,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ONGLET PHOTO (avec légende)
  // ═══════════════════════════════════════════════════════
    Widget _buildPhotoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── GRILLE D'IMAGES SÉLECTIONNÉES ────
          if (_imageBytesList.isEmpty)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 60, color: AppTheme.green),
                    SizedBox(height: 12),
                    Text(
                      'Choisir des photos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plusieurs photos possibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _imageBytesList.length + 1,
              itemBuilder: (context, i) {
                // Dernier item = bouton "ajouter"
                if (i == _imageBytesList.length) {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.add,
                          size: 40, color: AppTheme.green),
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
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 20),

          // ─── LÉGENDE ──────────────────────────
          const Text(
            'Légende',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _captionController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Écris une légende... (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}