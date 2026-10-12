import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'user_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final int userId;
  final bool showFollowers; // true = abonnés, false = abonnements
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final result = widget.showFollowers
        ? await UserService.getFollowers(widget.userId)
        : await UserService.getFollowing(widget.userId);

    if (!mounted) return;

    setState(() {
      _users = result['success'] == true ? result['users'] : [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showFollowers ? 'Abonnés' : 'Abonnements';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Text(
                    widget.showFollowers
                        ? 'Aucun abonné'
                        : 'Aucun abonnement',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1E40AF),
                        child: Text(
                          u.username.isNotEmpty
                              ? u.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        u.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${u.filiere}${u.niveau.isNotEmpty ? " · ${u.niveau}" : ""}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(userId: u.id),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}