import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/post_card.dart';
import 'follow_list_screen.dart';
import '../theme/app_theme.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  List<Post> _posts = [];
  bool _isFollowing = false;
  bool _isMe = false;
  bool _isLoading = true;
  bool _isFollowLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userResult = await UserService.getUser(widget.userId);
    if (!mounted) return;
    if (userResult['success'] != true) {
      setState(() {
        _error = userResult['error'] ?? 'Erreur';
        _isLoading = false;
      });
      return;
    }

    final postsResult = await UserService.getUserPosts(widget.userId);

    if (!mounted) return;

    setState(() {
      _user = userResult['user'];
      _isFollowing = userResult['isFollowing'] ?? false;
      _isMe = userResult['isMe'] ?? false;
      _posts = postsResult['success'] == true ? postsResult['posts'] : [];
      _isLoading = false;
    });
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;
    setState(() => _isFollowLoading = true);

    // Optimistic
    setState(() {
      _isFollowing = !_isFollowing;
    });

    final result = await UserService.toggleFollow(widget.userId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _isFollowing = result['data']['status'] == 'followed';
        _isFollowLoading = false;
      });
    } else {
      // Annuler
      setState(() {
        _isFollowing = !_isFollowing;
        _isFollowLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
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
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur : ${_error ?? "Utilisateur introuvable"}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAll,
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
        title: Text('@${user.username}'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ─── INFOS PROFIL ────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.green,
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pseudo
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Filière + niveau
                  if (user.filiere.isNotEmpty || user.niveau.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${user.filiere} ${user.niveau.isNotEmpty ? "· ${user.niveau}" : ""}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),

                  // Bio
                  if (user.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ─── COMPTEURS ───────────────────
                  Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _buildStat('${_posts.length}', 'Posts'),
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FollowListScreen(
              userId: widget.userId,
              showFollowers: true,
            ),
          ),
        );
      },
      child: _buildStat('${user.followersCount}', 'Abonnés'),
    ),
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FollowListScreen(
              userId: widget.userId,
              showFollowers: false,
            ),
          ),
        );
      },
      child: _buildStat('${user.followingCount}', 'Abonnements'),
    ),
  ],
),

                  const SizedBox(height: 16),

                  // ─── BOUTON FOLLOW ──────────────
                  if (!_isMe)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isFollowLoading ? null : _toggleFollow,
                        icon: Icon(
                          _isFollowing
                              ? Icons.person_remove_outlined
                              : Icons.person_add_outlined,
                        ),
                        label: Text(
                          _isFollowing ? 'Ne plus suivre' : 'Suivre',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? Colors.grey[300]
                              : const Color(0xFF1E40AF),
                          foregroundColor: _isFollowing
                              ? Colors.black87
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    const Text(
                      'C\'est ton profil',
                      style: TextStyle(color: Colors.grey),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            const Divider(height: 1),

            // ─── POSTS ────────────────────────
            if (_posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Aucun post',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._posts.map(
                (p) => PostCard(post: p, onRefresh: _loadAll),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }
}