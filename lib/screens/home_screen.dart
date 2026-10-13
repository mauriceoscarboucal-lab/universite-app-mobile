import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_bar.dart';
import 'login_screen.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _openCreatePost() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created == true) {
      _loadPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: _openCreatePost,
          backgroundColor: AppTheme.green,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        color: AppTheme.green,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ─── APPBAR (disparaît au scroll, revient seulement tout en haut) ───
            SliverAppBar(
              floating: false,
              pinned: false,
              snap: false,
              elevation: 0,
              backgroundColor: AppTheme.blue,
              foregroundColor: Colors.white,
              title: const Text(
                'Baobab',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.gradient,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadPosts,
                ),
              ],
            ),

            // ─── STORIES (disparaît avec l'AppBar) ───
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: const StoriesBar(),
              ),
            ),

            // ─── CONTENU ───
            ..._buildContentSlivers(),
          ],
        ),
      ),
    );
  }

  /// Renvoie les slivers correspondant au contenu (loading / erreur / vide / liste)
  List<Widget> _buildContentSlivers() {
    if (_isLoading) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        ),
      ];
    }

    if (_posts.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('Aucun post pour l\'instant')),
        ),
      ];
    }

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return PostCard(
              post: _posts[index],
              onRefresh: _loadPosts,
            );
          },
          childCount: _posts.length,
        ),
      ),
    ];
  }
}