import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../screens/comments_screen.dart';
import 'package:flutter/services.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onRefresh;

  const PostCard({super.key, required this.post, required this.onRefresh});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likesCount;
  bool _isLoadingLike = false;
  bool _isSaved = false;

  static const String _savedPostsKey = 'saved_posts';

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _checkIfSaved();
  }

  /// Vérifie si ce post est déjà enregistré
  Future<void> _checkIfSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedPostsKey) ?? [];
    if (mounted) {
      setState(() => _isSaved = saved.contains(widget.post.id.toString()));
    }
  }

  /// Enregistrer / Retirer des enregistrements
  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedPostsKey) ?? [];
    final id = widget.post.id.toString();

    if (saved.contains(id)) {
      saved.remove(id);
    } else {
      saved.add(id);
    }

    await prefs.setStringList(_savedPostsKey, saved);

    setState(() => _isSaved = !_isSaved);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Post enregistré 🔖' : 'Retiré des enregistrements'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;
    setState(() => _isLoadingLike = true);

    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    final result = await PostService.toggleLike(widget.post.id);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _likesCount = result['data']['likes_count'];
        _isLiked = result['data']['status'] == 'liked';
        _isLoadingLike = false;
      });
    } else {
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
        _isLoadingLike = false;
      });
    }
  }

    /// Partage : copie un lien dans le presse-papier
  Future<void> _share() async {
    final link =
        'https://universite-app.com/posts/${widget.post.id}\n\n— par @${widget.post.authorUsername}';
    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié dans le presse-papier 📋'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final timeAgo = timeago.format(post.createdAt, locale: 'fr');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── EN-TÊTE ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1E40AF),
                  child: Text(
                    post.authorUsername.isNotEmpty
                        ? post.authorUsername[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Pseudo + temps
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu 3 points
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    // À venir : options
                  },
                ),
              ],
            ),
          ),

          // ─── IMAGE ────────────────────────────
          if (post.image != null && post.image!.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.network(
                post.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),

          // ─── 4 ICÔNES ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black87,
                    size: 26,
                  ),
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined,
                      color: Colors.black87, size: 24),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(post: post),
                      ),
                    );
                    widget.onRefresh();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined,
                      color: Colors.black87, size: 24),
                  onPressed: _share,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.black87,
                    size: 26,
                  ),
                  onPressed: _toggleSave,
                ),
              ],
            ),
          ),

          // ─── LIKES ────────────────────────────
          if (_likesCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '$_likesCount j\'aime',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          // ─── LÉGENDE ──────────────────────────
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  children: [
                    TextSpan(
                      text: '${post.authorUsername} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post.content),
                  ],
                ),
              ),
            ),

          // ─── VOIR COMMENTAIRES ────────────────
          if (post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(post: post),
                    ),
                  );
                  widget.onRefresh();
                },
                child: Text(
                  'Voir les ${post.commentsCount} commentaires',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey[200]),
        ],
      ),
    );
  }
}