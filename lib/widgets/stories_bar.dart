import 'package:flutter/material.dart';
import '../models/story.dart';
import '../services/story_service.dart';
import '../screens/create_story_screen.dart';
import '../screens/story_viewer_screen.dart';
import '../theme/app_theme.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  List<StoryGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);

    final result = await StoryService.getStories();

    if (!mounted) return;

    setState(() {
      _groups = result['success'] == true ? result['groups'] : [];
      _isLoading = false;
    });
  }

  Future<void> _openCreateStory() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
    if (created == true) {
      _loadStories();
    }
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
    ).then((_) => _loadStories());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
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
              itemCount: _groups.length + 1, // +1 pour le bouton "Créer"
              itemBuilder: (context, index) {
                // Premier item : bouton "Ajouter une story"
                if (index == 0) {
                  return _buildAddStoryButton();
                }
                // Les autres : les stories des utilisateurs
                final group = _groups[index - 1];
                return _buildStoryCircle(group, index - 1);
              },
            ),
    );
  }

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
              child: const Icon(
                Icons.add,
                size: 32,
                color: AppTheme.green,
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
            // Cercle dégradé autour de l'avatar
            Container(
              width: 68,
              height: 68,
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
                        group.authorUsername.isNotEmpty
                            ? group.authorUsername[0].toUpperCase()
                            : '?',
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