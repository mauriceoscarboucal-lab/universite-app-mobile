import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'saved_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  final _usernameController = TextEditingController();
  final _filiereController = TextEditingController();
  final _niveauController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.getProfile();

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as User;
      setState(() {
        _user = user;
        _usernameController.text = user.username;
        _filiereController.text = user.filiere;
        _niveauController.text = user.niveau;
        _bioController.text = user.bio;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? 'Erreur';
        _isLoading = false;
      });
    }
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
      setState(() => _user = result['user']);
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

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur : $_error'),
              ElevatedButton(onPressed: _loadProfile, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(
                _user!.username.isNotEmpty
                    ? _user!.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
                        const SizedBox(height: 16),

            // Bouton "Posts enregistrés"
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedPostsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark_border),
                label: const Text('Posts enregistrés'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Email (non modifiable)
            Card(
              color: Colors.grey[100],
              child: ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF1E40AF)),
                title: const Text('Email'),
                subtitle: Text(_user!.email),
                trailing: const Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Username
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Pseudo',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Filière
            TextField(
              controller: _filiereController,
              decoration: const InputDecoration(
                labelText: 'Filière',
                prefixIcon: Icon(Icons.school_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Niveau
            TextField(
              controller: _niveauController,
              decoration: const InputDecoration(
                labelText: 'Niveau',
                prefixIcon: Icon(Icons.grade_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Bio
            TextField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Parle un peu de toi...',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Bouton enregistrer
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
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