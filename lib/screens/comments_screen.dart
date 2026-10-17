import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class CommentsScreen extends StatefulWidget {
  final Post post;
  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await PostService.getComments(widget.post.id);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _comments = result['comments'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? 'Erreur';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    final result = await PostService.addComment(widget.post.id, text);

    if (!mounted) return;

    if (result['success'] == true) {
      _commentController.clear();
      setState(() => _isSending = false);
      _loadComments();
    } else {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Commentaires', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.darkCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.authorUsername,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(widget.post.content, style: const TextStyle(color: AppTheme.textGrey)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderGreen),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brightGreen))
                : _error != null
                    ? Center(child: Text('Erreur : $_error', style: const TextStyle(color: Colors.white)))
                    : _comments.isEmpty
                        ? const Center(
                            child: Text('Aucun commentaire. Sois le premier !', style: TextStyle(color: AppTheme.textGrey)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final c = _comments[index];
                              return ListTile(
                                leading: UserAvatar(
                                  username: c.authorUsername,
                                  photo: c.authorPhoto,
                                  radius: 20,
                                ),
                                title: Text(
                                  c.authorUsername,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(c.content, style: const TextStyle(color: Colors.white)),
                              );
                            },
                          ),
          ),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.darkBg,
              border: Border(top: BorderSide(color: AppTheme.borderGreen)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Écrire un commentaire...',
                      hintStyle: const TextStyle(color: AppTheme.textGrey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brightGreen),
                        )
                      : const Icon(Icons.send, color: AppTheme.brightGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}