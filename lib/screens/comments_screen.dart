import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';

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
      _loadComments(); // recharge pour afficher le nouveau commentaire
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
      appBar: AppBar(
        title: const Text('Commentaires'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Aperçu du post
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.authorUsername,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(widget.post.content),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste des commentaires
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Erreur : $_error'))
                    : _comments.isEmpty
                        ? const Center(
                            child: Text('Aucun commentaire. Sois le premier !'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final c = _comments[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.green,
                                  child: Text(
                                    c.authorUsername.isNotEmpty
                                        ? c.authorUsername[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  c.authorUsername,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(c.content),
                              );
                            },
                          ),
          ),

          // Champ pour écrire un commentaire
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un commentaire...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: AppTheme.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}