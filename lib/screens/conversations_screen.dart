import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/conversation.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Conversation> _conversations = [];
  List<Conversation> _filtered = [];
  bool _isLoading = true;
  String? _error;
  int _myUserId = 0;
  final _searchController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _silentRefresh(),
    );
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final myId = await AuthService.getUserId();
    final result = await ChatService.getConversations();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _myUserId = myId;
        _conversations = result['conversations'];
        _applyFilter();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? 'Erreur';
        _isLoading = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    final result = await ChatService.getConversations();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _conversations = result['conversations'];
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filtered = List.from(_conversations);
    } else {
      _filtered = _conversations
          .where((c) =>
              c.otherUsername.toLowerCase().contains(query) ||
              (c.lastMessage ?? '').toLowerCase().contains(query))
          .toList();
    }
  }

  void _openChat(Conversation conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conv),
      ),
    ).then((_) => _loadAll());
  }

  Future<void> _openNewConversation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewConversationScreen(),
      ),
    );

    if (result is Conversation) {
      _openChat(result);
    }
  }

  // 🌳 Icône de statut (✓ ou ✓✓)
  Widget _buildListCheckIcon(Conversation conv) {
    if (conv.lastMessageIsRead) {
      return const Icon(Icons.done_all, size: 16, color: AppTheme.goldYellow);
    } else if (conv.lastMessageIsDelivered) {
      return const Icon(Icons.done_all, size: 16, color: AppTheme.textGrey);
    } else {
      return const Icon(Icons.done, size: 16, color: AppTheme.textGrey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg, // 🌙 FOND SOMBRE POUR L'ÉCRAN
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Nouvelle conversation',
            onPressed: _openNewConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── BARRE DE RECHERCHE ────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(_applyFilter),
              style: const TextStyle(color: Colors.white), // Texte blanc
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                hintStyle: const TextStyle(color: AppTheme.textGrey),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textGrey),
                        onPressed: () {
                          _searchController.clear();
                          setState(_applyFilter);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.darkCard, // Fond sombre du champ
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

          // ─── LISTE ─────────────────────────
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.brightGreen));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur : $_error', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAll,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 70, color: AppTheme.textGrey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'Aucune conversation' : 'Aucun résultat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty ? 'Appuie sur ✏️ pour démarrer une discussion' : 'Essaie un autre mot-clé',
              style: const TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.goldYellow,
      backgroundColor: AppTheme.darkCard,
      child: ListView.separated(
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderGreen, indent: 80),
        itemBuilder: (context, index) {
          final conv = _filtered[index];
          return _buildConversationTile(conv);
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv) {
    final isLastFromMe = conv.lastMessageSenderId == _myUserId;
    final timeAgo = conv.lastMessageAt != null
        ? timeago.format(conv.lastMessageAt!, locale: 'fr')
        : timeago.format(conv.updatedAt, locale: 'fr');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          UserAvatar(
            username: conv.otherUsername,
            photo: conv.otherPhoto,
            radius: 28,
          ),
          if (conv.unreadCount > 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.brightGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${conv.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
        title: Text(
        conv.otherUsername.isNotEmpty ? conv.otherUsername : 'Utilisateur',
        style: TextStyle(
          color: Colors.white, // <-- Ici on mettait du blanc
          fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            if (isLastFromMe)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildListCheckIcon(conv),
              ),
            Expanded(
              child: Text(
                conv.lastMessage ?? 'Nouvelle conversation',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: conv.unreadCount > 0 ? Colors.white : AppTheme.textGrey,
                  fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      trailing: Text(
        timeAgo,
        style: TextStyle(
          fontSize: 11,
          color: conv.unreadCount > 0 ? AppTheme.brightGreen : AppTheme.textGrey,
          fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _openChat(conv),
    );
  }
}