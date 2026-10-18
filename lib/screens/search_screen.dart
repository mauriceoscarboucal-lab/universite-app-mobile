import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<User> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final result = await UserService.searchUsers('');
    if (!mounted) return;
    setState(() {
      _results = result['success'] == true ? result['users'] : [];
      _isLoading = false;
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final result = await UserService.searchUsers(query);
    if (!mounted) return;
    setState(() {
      _results = result['success'] == true ? result['users'] : [];
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
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderGreen),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: _search,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Rechercher un étudiant...',
              hintStyle: TextStyle(color: AppTheme.textGrey),
              prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brightGreen))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderGreen, indent: 70),
              itemBuilder: (context, index) {
                final u = _results[index];
                return ListTile(
                  tileColor: Colors.transparent,
                  leading: UserAvatar(username: u.username, photo: u.photo, radius: 26),
                  title: Text(u.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${u.filiere}${u.niveau.isNotEmpty ? " · ${u.niveau}" : ""}', style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u.id))),
                );
              },
            ),
    );
  }
}