import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

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
      backgroundColor: AppTheme.darkBg, // 🌙 Fond sombre
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nouveau message', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // ─── BARRE DE RECHERCHE SOMBRE ────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              autofocus: true,
              style: const TextStyle(color: Colors.white), // Texte blanc
              decoration: InputDecoration(
                hintText: 'Rechercher un étudiant...',
                hintStyle: const TextStyle(color: AppTheme.textGrey),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                filled: true,
                fillColor: AppTheme.darkCard, // Fond de la barre
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.borderGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.borderGreen),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // ─── RÉSULTATS ─────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brightGreen))
                : _error != null
                    ? Center(child: Text('Erreur : $_error', style: const TextStyle(color: Colors.white)))
                    : _results.isEmpty
                        ? const Center(
                            child: Text('Aucun étudiant trouvé', style: TextStyle(color: AppTheme.textGrey)),
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderGreen, indent: 70),
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return ListTile(
                                tileColor: Colors.transparent, // Enlève le fond blanc par défaut
                                leading: UserAvatar(
                                  username: user.username,
                                  photo: user.photo,
                                  radius: 24,
                                ),
                                title: Text(
                                  user.username,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${user.filiere}${user.niveau.isNotEmpty ? " · ${user.niveau}" : ""}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                                ),
                                trailing: const Icon(Icons.chat_bubble_outline, color: AppTheme.brightGreen),
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