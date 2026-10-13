import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../screens/comments_screen.dart';
import 'package:flutter/services.dart';
import '../screens/user_profile_screen.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;
import '../services/api_config.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onRefresh;

  const PostCard({super.key, required this.post, required this.onRefresh});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
with SingleTickerProviderStateMixin  {
  late bool _isLiked;
  late int _likesCount;
  bool _isLoadingLike = false;
  bool _isSaved = false;

    // ❤️ Animation double-tap
  double? _tapX;
  double? _tapY;
  bool _showHeartOverlay = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  late Animation<Offset> _heartSlide;
  late Animation<Color?> _heartColor;

  late bool _isFollowingAuthor;
  bool _isFollowLoading = false;

  static const String _savedPostsKey = 'saved_posts';

    @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _isFollowingAuthor = widget.post.isFollowingAuthor;
    _checkIfSaved();

        // Animation du cœur (double-tap)
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9),
        weight: 50,
      ),
    ]).animate(_heartController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(_heartController);

    _heartSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.2),
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

        _heartColor = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF00C853), // Vert
          end: const Color(0xFF00C853),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF00C853),
          end: const Color(0xFFD50000), // Rouge
        ),
        weight: 50,
      ),
    ]).animate(_heartController);
  }

    void _handleDoubleTap(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    setState(() {
      _tapX = localPosition.dx;
      _tapY = localPosition.dy - 100; // ajustement pour centrer sur l'image
      _showHeartOverlay = true;
    });

    // Si pas encore liké, on like
    if (!_isLiked) {
      _toggleLike();
    }

    _heartController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeartOverlay = false);
    });
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

    Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;
    setState(() => _isFollowLoading = true);

    // Optimistic update
    setState(() => _isFollowingAuthor = !_isFollowingAuthor);

    final result = await UserService.toggleFollow(widget.post.author);

    if (!mounted) return;

    if (result['success'] == true) {
      final isNowFollowing = result['data']['status'] == 'followed';
      setState(() {
        _isFollowingAuthor = isNowFollowing;
        _isFollowLoading = false;
      });

      // ✨ Animation : SnackBar stylée
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isNowFollowing ? Icons.check_circle : Icons.info_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                isNowFollowing
                    ? 'Tu suis maintenant @${widget.post.authorUsername}'
                    : 'Tu ne suis plus @${widget.post.authorUsername}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor:
              isNowFollowing ? Colors.green[600] : Colors.grey[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );

      // Rafraîchit le feed après un petit délai pour que le bouton disparaisse joliment
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) widget.onRefresh();
    } else {
      setState(() {
        _isFollowingAuthor = !_isFollowingAuthor;
        _isFollowLoading = false;
      });
    }
  }

  /// Affiche le menu des options (Signaler / Supprimer)
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Petite barre grise en haut
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ─── SI C'EST MON POST ───────────────
              if (widget.post.isMyPost) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  title: const Text(
                    'Supprimer la publication',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Modifier'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Modification à venir 🚧'),
                      ),
                    );
                  },
                ),
              ]

              // ─── SI C'EST LE POST D'UN AUTRE ─────
              else ...[
                ListTile(
                  leading: const Icon(Icons.flag_outlined,
                      color: Colors.red),
                  title: const Text(
                    'Signaler',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _reportPost();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('En savoir plus sur @${widget.post.authorUsername}'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          userId: widget.post.author,
                        ),
                      ),
                    );
                  },
                ),
              ],

              // ─── OPTIONS COMMUNES ────────────────
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copier le lien'),
                onTap: () {
                  Navigator.pop(context);
                  _share();
                },
              ),
              ListTile(
                leading: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                ),
                title: Text(_isSaved ? 'Retirer des enregistrements' : 'Enregistrer'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleSave();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Confirmation de suppression
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce post ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await PostService.deletePost(widget.post.id);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publication supprimée ✅'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

  /// Signaler un post
  Future<void> _reportPost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Signaler cette publication ?'),
        content: const Text(
          'Cette publication sera examinée par notre équipe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Signaler',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Merci, ton signalement a été pris en compte ✅'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final timeAgo = timeago.format(post.createdAt, locale: 'fr');

    int _currentImageIndex = 0;
    final PageController _pageController = PageController();

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
                                // Avatar (cliquable)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: post.author),
                      ),
                    );
                  },
                  child: CircleAvatar(
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
                ),
                const SizedBox(width: 10),

                                // Pseudo + temps (cliquable) + bouton Suivre
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: post.author),
                        ),
                      );
                    },
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
                ),

                // Bouton Suivre (visible uniquement si :
                // - on ne suit pas encore
                // - ce n'est PAS notre propre post)
                if (!_isFollowingAuthor && !widget.post.isMyPost)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _isFollowLoading ? null : _toggleFollow,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E40AF),
                          backgroundColor:
                              const Color(0xFF1E40AF).withOpacity(0.08),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isFollowLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Suivre',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ),

                                // Menu 3 points
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _showOptionsMenu,
                ),
              ],
            ),
          ),

                    // ─── IMAGE(S) AVEC DOUBLE-TAP ─────────────
          if ((post.images.isNotEmpty) ||
              (post.image != null && post.image!.isNotEmpty))
            Stack(
              children: [
                GestureDetector(
                  onDoubleTapDown: _handleDoubleTap,
                  onDoubleTap: () {},
                  child: post.images.isNotEmpty
                      ? SizedBox(
                          height: 400,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: post.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIndex = i),
                            itemBuilder: (context, i) {
                              return Image.network(
                                ApiConfig.fullUrl(post.images[i]),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, size: 60),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
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
                ),

                // Indicateur "1/3" en haut à droite
                if (post.images.length > 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${post.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // ❤️ Cœur animé
                if (_showHeartOverlay && _tapX != null && _tapY != null)
                  Positioned(
                    left: _tapX! - 50,
                    top: _tapY!,
                    child: SlideTransition(
                      position: _heartSlide,
                      child: FadeTransition(
                        opacity: _heartOpacity,
                        child: ScaleTransition(
                          scale: _heartScale,
                          child: AnimatedBuilder(
                            animation: _heartColor,
                            builder: (context, _) => Icon(
                              Icons.favorite,
                              color: _heartColor.value ?? Colors.red,
                              size: 100,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else if (post.backgroundColor.isNotEmpty &&
              post.content.isNotEmpty)
            // Post texte avec fond coloré
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              color: _hexToColor(post.backgroundColor),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              child: Center(
                child: Text(
                  post.content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: _isDarkColor(post.backgroundColor)
                        ? Colors.white
                        : Colors.black87,
                  ),
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

                    // ─── LÉGENDE (uniquement si pas déjà affichée sur fond) ──
          if (post.content.isNotEmpty &&
              (post.image != null || post.backgroundColor.isEmpty))
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

  Color _hexToColor(String hex) {
    if (hex.isEmpty) return Colors.white;
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  bool _isDarkColor(String hex) {
    final color = _hexToColor(hex);
    return color.computeLuminance() < 0.5;
  }

}