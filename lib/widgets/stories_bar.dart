import 'package:flutter/material.dart';
import '../models/story.dart';
import '../services/auth_service.dart';
import '../services/story_service.dart';
import '../screens/create_story_screen.dart';
import '../screens/story_viewer_screen.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  List<StoryGroup> _groups = [];
  StoryGroup? _myGroup;
  int _myUserId = 0;
  String _myUsername = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

    Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final myId = await AuthService.getUserId();
    final profileResult = await AuthService.getProfile();
    final result = await StoryService.getStories();

    if (!mounted) return;

    String myUsername = '';
    if (profileResult['success'] == true) {
      myUsername = profileResult['user'].username ?? '';
    }

    if (!mounted) return;

    final groups = result['success'] == true
        ? result['groups'] as List<StoryGroup>
        : <StoryGroup>[];

    // On sépare MON groupe des autres
    StoryGroup? myGroup;
    final others = <StoryGroup>[];
    for (final g in groups) {
      if (g.authorId == myId) {
        myGroup = g;
      } else {
        others.add(g);
      }
    }

    setState(() {
      _myUserId = myId;
      _myUsername = myUsername;
      _myGroup = myGroup;
      _groups = others;
      _isLoading = false;
    });
  }

  Future<void> _openCreateStory() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
    if (created == true) {
      _loadAll();
    }
  }

  void _openMyStory() {
    if (_myGroup == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          groups: [_myGroup!, ..._groups],
          initialGroupIndex: 0,
        ),
      ),
    ).then((_) => _loadAll());
  }

  void _openStory(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          groups: _groups,
          initialGroupIndex: index,
        ),
      ),
    ).then((_) => _loadAll());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _groups.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Premier item : Ma story (ou bouton + si pas de story)
                  return _myGroup == null
                      ? _buildAddStoryButton()
                      : _buildMyStoryWithAdd();
                }
                return _buildStoryCircle(_groups[index - 1], index - 1);
              },
            ),
    );
  }

  /// Cas 1 : je n'ai PAS de story → bouton "Ma story" avec grand +
  Widget _buildAddStoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: _openCreateStory,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
                color: Colors.grey[100],
              ),
              child: const Icon(Icons.add, size: 32, color: AppTheme.green),
            ),
            const SizedBox(height: 4),
            const SizedBox(
              width: 70,
              child: Text(
                'Ma story',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cas 2 : j'ai une story → mon avatar + petit +
  Widget _buildMyStoryWithAdd() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              children: [
                // Avatar avec dégradé
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _openMyStory,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.storyGradient,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              backgroundColor: AppTheme.green,
                              child: Text(
                                _myUsername.isNotEmpty
                                    ? _myUsername[0].toUpperCase()
                                    : 'M',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Petit + en bas à droite pour ajouter une autre story
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _openCreateStory,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(
            width: 70,
            child: Text(
              'Ma story',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCircle(StoryGroup group, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => _openStory(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cercle dégradé ou gris selon si vu
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: group.allViewed ? null : AppTheme.storyGradient,
                color: group.allViewed ? Colors.grey[400] : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                      child: UserAvatar(
                        username: group.authorUsername,
                        photo: group.authorPhoto,
                        radius: 28,
                      )
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                group.authorUsername,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}