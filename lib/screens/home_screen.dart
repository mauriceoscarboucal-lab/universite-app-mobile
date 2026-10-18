import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/notification_service.dart'; // <-- NOUVEAU
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_bar.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';          // <-- NOUVEAU
import 'profile_screen.dart';         // <-- NOUVEAU
import 'notifications_screen.dart';   // <-- NOUVEAU

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
  Timer? _refreshTimer;
  Timer? _notifTimer; // <-- NOUVEAU TIMER
  
  int _unreadNotifs = 0; // Badge notifications

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _startAutoRefresh();
    _loadNotifs(); // Appel de la méthode
    _startNotifRefresh(); // <-- AJOUTE CA
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notifTimer?.cancel(); // <-- AJOUTE CA
    _scrollController.dispose();
    super.dispose();
  }

  // ─── MÉTHODES ───

  Future<void> _loadNotifs() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifs = count);
  }

    void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2), // ⚡ 2 secondes pour le temps réel
      (_) => _silentRefresh(),
    );
  }

  Future<void> _silentRefresh() async {
    final result = await PostService.getPosts();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _posts = result['posts']);
    }
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
      backgroundColor: AppTheme.darkBg,
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        color: AppTheme.goldYellow,
        backgroundColor: AppTheme.darkCard,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ─── APPBAR ───
            SliverAppBar(
              backgroundColor: AppTheme.darkBg,
              elevation: 0,
              floating: true,
              snap: true,
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: AppTheme.brightGreen),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BAOBAB', style: TextStyle(color: AppTheme.goldYellow, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2)),
                      Text('Plus qu\'un réseau, une communauté', style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              actions: [
                // 🔍 Bouton Recherche
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                  },
                ),
                // 🔔 Bouton Notifications (avec Badge)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        _loadNotifs(); // Rafraîchit le compteur au retour
                      },
                    ),
                    if (_unreadNotifs > 0)
                      Positioned(
                        right: 6,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('$_unreadNotifs', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                // 👤 Bouton Profil
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.brightGreen,
                      child: Icon(Icons.person, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            // ─── STORIES ───
            SliverToBoxAdapter(child: Container(color: AppTheme.darkBg, child: const StoriesBar())),

            // ─── QUOI DE NEUF ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.darkCard,
                      child: Icon(Icons.person, color: AppTheme.textGrey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _openCreatePost,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppTheme.borderGreen),
                          ),
                          child: const Text('Quoi de neuf ?', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.image_outlined, color: AppTheme.brightGreen),
                      onPressed: _openCreatePost,
                    ),
                  ],
                ),
              ),
            ),

            // ─── FEED ───
            ..._buildContentSlivers(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers() {
    if (_isLoading) {
      return [const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: AppTheme.goldYellow)))];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Erreur : $_error', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadPosts, child: const Text('Réessayer')),
              ],
            ),
          ),
        )
      ];
    }
    if (_posts.isEmpty) {
      return [const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Aucun post', style: TextStyle(color: AppTheme.textGrey))))];
    }

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => PostCard(
            key: ValueKey(_posts[index].id),
            post: _posts[index], 
            onRefresh: _silentRefresh, // <-- MISE À JOUR SILENCIEUSE
          ),
          childCount: _posts.length,
        ),
      ),
    ];
  }
  void _startNotifRefresh() {
    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(
      const Duration(seconds: 2), // ⚡ 2 secondes pour la cloche
      (_) => _loadNotifs(),
    );
  }
}