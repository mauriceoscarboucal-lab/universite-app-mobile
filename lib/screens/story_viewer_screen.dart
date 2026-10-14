import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/story.dart';
import '../services/api_config.dart';
import '../services/story_service.dart';
import '../services/auth_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentGroupIndex;
  late int _currentStoryIndex;
  late AnimationController _progressController;
  Timer? _autoNextTimer;
  int _myUserId = 0;

  static const Duration _storyDuration = Duration(seconds: 30);

    @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _currentStoryIndex = 0;

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    _loadMyId();                            // <-- AJOUTE
    _startStory();
  }

  Future<void> _loadMyId() async {          // <-- AJOUTE la méthode
    final id = await AuthService.getUserId();
    if (mounted) setState(() => _myUserId = id);
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  StoryGroup get _currentGroup => widget.groups[_currentGroupIndex];
  Story get _currentStory => _currentGroup.stories[_currentStoryIndex];

    void _startStory() {
    _autoNextTimer?.cancel();
    _progressController.forward(from: 0);

    // 📌 Marque cette story comme vue par moi (sauf si c'est la mienne)
    if (_currentGroup.authorId != _myUserId) {
      StoryService.markViewed(_currentStory.id);
    }

    // Timer auto : à la fin, on passe à la story suivante
    _autoNextTimer = Timer(_storyDuration, () {
      if (mounted) _next();
    });
  }

  void _next() {
    if (_currentStoryIndex < _currentGroup.stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _startStory();
    } else if (_currentGroupIndex < widget.groups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previous() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startStory();
    } else if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = 0;
      });
      _startStory();
    } else {
      // Déjà à la 1ère story → on remet à zéro
      _startStory();
    }
  }

  Future<void> _deleteCurrentStory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette story ?'),
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

    final result = await StoryService.deleteStory(_currentStory.id);
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

    /// Ouvre la liste des personnes qui ont vu cette story
  Future<void> _showViewersSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => _ViewersSheet(
          storyId: _currentStory.id,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final timeAgo = timeago.format(story.createdAt, locale: 'fr');

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Tap gauche / droite pour naviguer manuellement
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 2) {
            _previous();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) {
          // Pause quand on appuie longtemps
          _autoNextTimer?.cancel();
          _progressController.stop();
        },
        onLongPressEnd: (_) {
          // Reprend quand on relâche
          _progressController.forward();
          final remaining =
              _storyDuration * (1 - _progressController.value);
          _autoNextTimer = Timer(remaining, () {
            if (mounted) _next();
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ─── IMAGE ─────────────────────
            Image.network(
              ApiConfig.fullUrl(story.image),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image,
                    size: 80, color: Colors.white54),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
            ),

            // ─── DÉGRADÉ HAUT ──────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ─── BARRE DE PROGRESSION ANIMÉE ─
            Positioned(
              top: 40,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  _currentGroup.stories.length,
                  (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: i < _currentStoryIndex
                          // Stories déjà vues : barre pleine
                          ? Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : i == _currentStoryIndex
                              // Story en cours : barre animée
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, _) => Container(
                                    height: 3,
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: Colors.white38,
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor:
                                          _progressController.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              // Stories futures : barre vide
                              : Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white38,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── EN-TÊTE ────────────────────
            Positioned(
              top: 56,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1E40AF),
                    child: Text(
                      _currentGroup.authorUsername.isNotEmpty
                          ? _currentGroup.authorUsername[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentGroup.authorUsername,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                                    // 👁️ Bouton "qui a vu" (uniquement si c'est ma story)
                  if (_currentGroup.authorId == _myUserId)
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined,
                          color: Colors.white),
                      tooltip: 'Qui a vu',
                      onPressed: _showViewersSheet,
                    ),

                  // 🗑️ Supprimer (uniquement si c'est ma story)
                  if (_currentGroup.authorId == _myUserId)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white),
                      onPressed: _deleteCurrentStory,
                    ),

                  // ✖️ Fermer
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── LÉGENDE ───────────────────
            if (story.caption.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    story.caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _ViewersSheet extends StatefulWidget {
  final int storyId;
  final ScrollController scrollController;

  const _ViewersSheet({
    required this.storyId,
    required this.scrollController,
  });

  @override
  State<_ViewersSheet> createState() => _ViewersSheetState();
}

class _ViewersSheetState extends State<_ViewersSheet> {
  List<StoryViewer> _viewers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await StoryService.getViewers(widget.storyId);
    if (!mounted) return;
    setState(() {
      _viewers = result['success'] == true ? result['viewers'] : [];
      _isLoading = false;
      if (result['success'] != true) {
        _error = result['error'] ?? 'Erreur';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre grise
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.visibility, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_viewers.length} vue${_viewers.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Erreur : $_error'))
                  : _viewers.isEmpty
                      ? const Center(
                          child: Text(
                            'Personne n\'a encore vu cette story',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: widget.scrollController,
                          itemCount: _viewers.length,
                          itemBuilder: (context, index) {
                            final v = _viewers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00C853),
                                child: Text(
                                  v.username.isNotEmpty
                                      ? v.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                v.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${v.filiere}${v.niveau.isNotEmpty ? " · ${v.niveau}" : ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}