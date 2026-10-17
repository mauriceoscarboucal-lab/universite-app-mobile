import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/post_card.dart';
import 'saved_posts_screen.dart';
import 'settings_screen.dart';
import 'follow_list_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  User? _user;
  List<Post> _myPosts = [];
  bool _isLoading = true;
  String? _error;

  // Édition du profil
  bool _isEditing = false;
  bool _isSaving = false;

  final _usernameController = TextEditingController();
  final _filiereController = TextEditingController();
  final _niveauController = TextEditingController();
  final _bioController = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.getProfile();
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() {
        _error = result['error'] ?? 'Erreur';
        _isLoading = false;
      });
      return;
    }

    final user = result['user'] as User;
    final postsResult = await UserService.getUserPosts(user.id);

    if (!mounted) return;

    setState(() {
      _user = user;
      _usernameController.text = user.username;
      _filiereController.text = user.filiere;
      _niveauController.text = user.niveau;
      _bioController.text = user.bio;
      _myPosts = postsResult['success'] == true ? postsResult['posts'] : [];
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final result = await AuthService.updateProfile(
      username: _usernameController.text.trim(),
      filiere: _filiereController.text.trim(),
      niveau: _niveauController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      setState(() {
        _user = result['user'];
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openSaved() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
    );
  }

  void _openFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: _user!.id,
          showFollowers: true,
        ),
      ),
    );
  }

  void _openFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: _user!.id,
          showFollowers: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur : ${_error ?? "Inconnue"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user!;

    return Scaffold(
       appBar: AppBar(
        title: Text(user.username),
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.gradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _buildHeader(user)),
            SliverPersistentHeader(
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.green,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.green,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.bookmark_border)),
                  ],
                ),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // ─── ONGLET POSTS ────────────────
              _myPosts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Aucune publication',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _myPosts.length,
                      itemBuilder: (context, index) {
                        return PostCard(
                          post: _myPosts[index],
                          onRefresh: _loadProfile,
                        );
                      },
                    ),

              // ─── ONGLET ENREGISTRÉS ─────────
              Center(
                child: TextButton.icon(
                  onPressed: _openSaved,
                  icon: const Icon(Icons.bookmark),
                  label: const Text('Voir mes posts enregistrés'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── AVATAR + STATS ────────────────
          Row(
            children: [
                            Stack(
                children: [
                  UserAvatar(
                    username: user.username,
                    photo: user.photo,
                    radius: 40,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _changePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.brightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('${_myPosts.length}', 'publications'),
                    GestureDetector(
                      onTap: _openFollowers,
                      child: _buildStat(
                          '${user.followersCount}', 'abonnés'),
                    ),
                    GestureDetector(
                      onTap: _openFollowing,
                      child: _buildStat(
                          '${user.followingCount}', 'suivis'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── NOM + BIO ───────────────────
          if (!_isEditing) ...[
            Text(
              user.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (user.filiere.isNotEmpty || user.niveau.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${user.filiere}${user.niveau.isNotEmpty ? " · ${user.niveau}" : ""}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            if (user.bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(user.bio, style: const TextStyle(fontSize: 14)),
              ),
            const SizedBox(height: 12),

            // ─── BOUTONS ──────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Modifier le profil'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lien de profil copié 📋'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(60, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.share_outlined, size: 18),
                ),
              ],
            ),
          ] else ...[
            // ─── FORMULAIRE D'ÉDITION ────────
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Pseudo',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _filiereController,
              decoration: const InputDecoration(
                labelText: 'Filière',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _niveauController,
              decoration: const InputDecoration(
                labelText: 'Niveau',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }
    final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;

  // Méthode pour choisir et uploader une photo
  Future<void> _changePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer ma photo',
            toolbarColor: AppTheme.brightGreen,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Recadrer ma photo',
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 500, height: 500),
          ),
        ],
      );

      if (cropped == null) return;

      final bytes = await cropped.readAsBytes();

      setState(() => _isUploadingPhoto = true);

     final fileName = cropped.path.split('/').last;
      
      final result = await AuthService.uploadPhoto(
        photoBytes: bytes,
        photoName: fileName.isNotEmpty ? fileName : 'profile_photo.jpg',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo mise à jour ! 🎉'), backgroundColor: Colors.green),
        );
        _loadProfile(); // Recharge le profil pour afficher la nouvelle photo
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Erreur')),
        );
      }
      setState(() => _isUploadingPhoto = false);
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }
}

/// Delegate pour épingler le TabBar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_) => false;
}