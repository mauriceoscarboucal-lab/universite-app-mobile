import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/conversation.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';
import '../widgets/baobab_check_icon.dart';

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
      const Duration(seconds: 3),       // ⚡ 3 secondes
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
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
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
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.green),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(_applyFilter);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur : $_error'),
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
            Icon(Icons.chat_bubble_outline,
                size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Aucune conversation'
                  : 'Aucun résultat',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Appuie sur ✏️ pour démarrer une discussion'
                  : 'Essaie un autre mot-clé',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.green,
      child: ListView.separated(
        itemCount: _filtered.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final conv = _filtered[index];
          return _buildConversationTile(conv);
        },
      ),
    );
  }

      /// 🌳 Baobabs de statut du dernier message
  Widget _buildListCheckIcon(Conversation conv) {
    if (conv.lastMessageIsRead) {
      return const BaobabCheckIcon(
        size: 14,
        color: Color(0xFFFFD600),
        count: 2,
      );
    } else if (conv.lastMessageIsDelivered) {
      return const BaobabCheckIcon(
        size: 14,
        color: Colors.grey,
        count: 2,
      );
    } else {
      return const BaobabCheckIcon(
        size: 14,
        color: Colors.grey,
        count: 1,
      );
    }
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
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.green,
            child: Text(
              conv.otherUsername.isNotEmpty
                  ? conv.otherUsername[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          if (conv.unreadCount > 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: AppTheme.gradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${conv.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        conv.otherUsername,
        style: TextStyle(
          fontWeight: conv.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.w600,
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
                  color: conv.unreadCount > 0
                      ? Colors.black87
                      : Colors.grey[600],
                  fontWeight: conv.unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
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
          color: conv.unreadCount > 0 ? AppTheme.green : Colors.grey,
          fontWeight:
              conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _openChat(conv),
    );
  }
}