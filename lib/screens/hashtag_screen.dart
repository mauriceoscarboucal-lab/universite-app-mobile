import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';

class HashtagScreen extends StatefulWidget {
  final String tag;
  const HashtagScreen({super.key, required this.tag});

  @override
  State<HashtagScreen> createState() => _HashtagScreenState();
}

class _HashtagScreenState extends State<HashtagScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await PostService.getPostsByHashtag(widget.tag);
    if (!mounted) return;
    setState(() {
      _posts = result['success'] == true ? result['posts'] : [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        title: Text('#${widget.tag}', style: const TextStyle(color: AppTheme.goldYellow, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brightGreen))
          : _posts.isEmpty
              ? Center(
                  child: Text(
                    'Aucune publication avec #${widget.tag}',
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                )
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    return PostCard(
                      post: _posts[index],
                      onRefresh: _load,
                    );
                  },
                ),
    );
  }
}