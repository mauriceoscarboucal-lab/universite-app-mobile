import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import '../theme/app_theme.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  static const String _savedPostsKey = 'saved_posts';

  List<Post> _savedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_savedPostsKey) ?? [];

    if (savedIds.isEmpty) {
      setState(() {
        _savedPosts = [];
        _isLoading = false;
      });
      return;
    }

    // Charge chaque post depuis l'API
    final List<Post> posts = [];
    for (final idStr in savedIds) {
      final id = int.tryParse(idStr);
      if (id == null) continue;

      final result = await PostService.getPostById(id);
      if (result['success'] == true) {
        posts.add(Post.fromJson(result['data']));
      }
    }

    if (!mounted) return;
    setState(() {
      _savedPosts = posts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts enregistrés'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Aucun post enregistré',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedPosts,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _savedPosts.length,
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: _savedPosts[index],
                        onRefresh: _loadSavedPosts,
                      );
                    },
                  ),
                ),
    );
  }
}