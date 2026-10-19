import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../screens/comments_screen.dart';
import '../screens/user_profile_screen.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onRefresh;

  const PostCard({super.key, required this.post, required this.onRefresh});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  late bool _isFollowingAuthor;
  bool _isSaved = false;
  bool _isFollowLoading = false;
  
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // ❤️ Animation Double-Tap
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  double? _tapX;
  double? _tapY;
  bool _showHeartOverlay = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _isFollowingAuthor = widget.post.isFollowingAuthor;
    _checkIfSaved();

    // Initialisation de l'animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 60),
    ]).animate(_heartController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(_heartController);
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si les données du serveur ont changé, on met à jour l'affichage local
    if (oldWidget.post.likesCount != widget.post.likesCount || 
        oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.isFollowingAuthor != widget.post.isFollowingAuthor) { // <-- AJOUTE CETTE LIGNE
      
      setState(() {
        _likesCount = widget.post.likesCount;
        _isLiked = widget.post.isLiked;
        _isFollowingAuthor = widget.post.isFollowingAuthor; // <-- AJOUTE CETTE LIGNE
      });
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_posts') ?? [];
    if (mounted) setState(() => _isSaved = saved.contains(widget.post.id.toString()));
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_posts') ?? [];
    final id = widget.post.id.toString();
    if (saved.contains(id)) { saved.remove(id); } else { saved.add(id); }
    await prefs.setStringList('saved_posts', saved);
    setState(() => _isSaved = !_isSaved);
  }

  Future<void> _toggleLike() async {
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
      });
      widget.onRefresh(); // <-- FORCE LE FEED PARENT A SE METTRE A JOUR
    } else {
      // En cas d'erreur, on annule
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
    }
  }

    Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;
    setState(() => _isFollowLoading = true);
    setState(() => _isFollowingAuthor = !_isFollowingAuthor);
    
    final result = await UserService.toggleFollow(widget.post.author);
    if (!mounted) return;
    
    if (result['success'] == true) {
      setState(() {
        _isFollowingAuthor = result['data']['status'] == 'followed';
        _isFollowLoading = false;
      });
      // 🔄 Force le rafraîchissement de TOUT le feed instantanément
      widget.onRefresh(); 
    } else {
      setState(() {
        _isFollowingAuthor = !_isFollowingAuthor;
        _isFollowLoading = false;
      });
    }
  }

  // ❤️ Gestion du double-clic
  void _handleDoubleTap(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    setState(() {
      _tapX = localPosition.dx - 40; // Centrer le cœur
      _tapY = localPosition.dy - 80; // Ajuster selon l'écran
      _showHeartOverlay = true;
    });

    if (!_isLiked) {
      _toggleLike();
    }

    _heartController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeartOverlay = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final timeAgo = timeago.format(post.createdAt, locale: 'fr');
    
    final List<String> displayImages = post.images.isNotEmpty 
        ? post.images 
        : (post.image != null && post.image!.isNotEmpty ? [post.image!] : []);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── EN-TÊTE ───
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.author))),
                  child: UserAvatar(
                    username: post.authorUsername,
                    photo: post.authorPhoto,
                    radius: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NOM SANS BADGE VÉRIFIÉ
                      Text(post.authorUsername, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(timeAgo, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                if (!post.isMyPost && !_isFollowingAuthor)
                  TextButton(
                    onPressed: _isFollowLoading ? null : _toggleFollow,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.brightGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: _isFollowLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Suivre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                GestureDetector(
                  onTapUp: (details) {
                    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                    _showOptionsMenu(context, details.globalPosition, overlay);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.more_horiz, color: AppTheme.textGrey),
                  ),
                ),
              ],
            ),
          ),

          // ─── TEXTE ───
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
            ),

          const SizedBox(height: 12),

          // ─── CARROUSEL AVEC DOUBLE-TAP ET ANIMATION ───
          if (displayImages.isNotEmpty)
            Stack(
              children: [
                GestureDetector(
                  onDoubleTapDown: _handleDoubleTap,
                  onDoubleTap: () {}, // Nécessaire pour activer le double tap
                  child: SizedBox(
                    height: 350,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: displayImages.length,
                      onPageChanged: (i) => setState(() => _currentImageIndex = i),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              ApiConfig.fullUrl(displayImages[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.darkBg,
                                child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textGrey)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // L'ANIMATION DU CŒUR JAUNE
                if (_showHeartOverlay && _tapX != null && _tapY != null)
                  Positioned(
                    left: _tapX!,
                    top: _tapY!,
                    child: FadeTransition(
                      opacity: _heartOpacity,
                      child: ScaleTransition(
                        scale: _heartScale,
                        child: const Icon(
                          Icons.favorite,
                          color: AppTheme.goldYellow,
                          size: 80,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),

                // Badge 1/20
                if (displayImages.length > 1)
                  Positioned(
                    top: 12,
                    right: 28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${_currentImageIndex + 1}/${displayImages.length}', 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 12),

          // ─── ACTIONS ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : AppTheme.textGrey, size: 24),
                      const SizedBox(width: 4),
                      Text('$_likesCount', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => CommentsScreen(post: post),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0); // Commence en bas
                          const end = Offset.zero; // Finit à sa place
                          const curve = Curves.easeOutCubic; // Courbe fluide
                          
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                    widget.onRefresh();
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: AppTheme.textGrey, size: 22),
                      const SizedBox(width: 4),
                      Text('${post.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.share_outlined, color: AppTheme.textGrey, size: 22),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleSave,
                  child: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isSaved ? AppTheme.goldYellow : AppTheme.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  void _showOptionsMenu(BuildContext context, Offset position, RenderBox overlay) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      color: AppTheme.darkCard, // Fond sombre
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderGreen), // Bordure verte
      ),
      items: [
        if (widget.post.isMyPost)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Supprimer', style: TextStyle(color: Colors.red)),
              ],
            ),
          )
        else ...[
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Signaler', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('À propos de @${widget.post.authorUsername}', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Copier le lien', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );

    // Gestion des actions du menu
    if (result == 'delete') {
      // Appeler ta fonction de suppression de post ici
      _confirmDelete();
    } else if (result == 'report') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement envoyé')));
    } else if (result == 'info') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.post.author)));
    } else if (result == 'copy') {
      // Copier le lien
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien copié 📋')));
    }
  }
    Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Supprimer ce post ?', style: TextStyle(color: Colors.white)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: AppTheme.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // On appelle l'API pour supprimer
    final result = await PostService.deletePost(widget.post.id);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publication supprimée ✅'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onRefresh(); // Rafraîchit le feed pour retirer la carte
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur lors de la suppression')),
      );
    }
  }
}