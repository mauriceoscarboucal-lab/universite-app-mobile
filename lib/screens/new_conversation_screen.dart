import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final _searchController = TextEditingController();
  List<User> _results = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await UserService.searchUsers(query);

    if (!mounted) return;

    setState(() {
      _results = result['success'] == true ? result['users'] : [];
      _isLoading = false;
      if (result['success'] != true) {
        _error = result['error'] ?? 'Erreur';
      }
    });
  }

  Future<void> _startConversation(User user) async {
    final result = await ChatService.startConversation(user.id);

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, result['conversation']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.gradient),
        ),
        title: const Text('Nouveau message'),
      ),
      body: Column(
        children: [
          // ─── BARRE DE RECHERCHE ────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher un étudiant...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // ─── RÉSULTATS ─────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Erreur : $_error'))
                    : _results.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun étudiant trouvé',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 70),
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.green,
                                  child: Text(
                                    user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${user.filiere}${user.niveau.isNotEmpty ? " · ${user.niveau}" : ""}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.chat_bubble_outline,
                                    color: AppTheme.green),
                                onTap: () => _startConversation(user),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}