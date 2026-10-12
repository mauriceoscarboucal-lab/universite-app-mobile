import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import 'login_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await PostService.getPosts();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _posts = result['posts'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? 'Erreur';
        _isLoading = false;
      });
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
        return Scaffold(
      appBar: AppBar(
        title: const Text('Fil d\'actualité'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
  IconButton(
    icon: const Icon(Icons.refresh),
    onPressed: _loadPosts,
  ),
  IconButton(
    icon: const Icon(Icons.person),
    tooltip: 'Mon profil',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    },
  ),
],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (created == true) {
            _loadPosts(); // rafraîchit la liste après création
          }
        },
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? const Center(child: Text('Aucun post pour l\'instant'))
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
  padding: EdgeInsets.zero,
  itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return PostCard(
                            post: _posts[index],
                            onRefresh: _loadPosts,
                          );
                        },
                      ),
                    ),
    );
  }
}