import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/conversation.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/baobab_check_icon.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  int _myUserId = 0;
  Timer? _refreshTimer;

  late Conversation _conversation;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _loadMyIdAndMessages();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

   void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),      // ⚡ 2 secondes
      (_) => _silentRefresh(),
    );
  }

  Future<void> _loadMyIdAndMessages() async {
    final id = await AuthService.getUserId();
    if (mounted) setState(() => _myUserId = id);
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ChatService.getMessages(
      _conversation.id,
      markRead: true,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _messages = result['messages'];
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() {
        _error = result['error'] ?? 'Erreur';
        _isLoading = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    final result = await ChatService.getMessages(
      _conversation.id,
      markRead: true,       // ✅ On lit les messages en direct
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final newMessages = result['messages'] as List<Message>;

        bool needsUpdate = newMessages.length != _messages.length;
      if (!needsUpdate && newMessages.length == _messages.length) {
        for (int i = 0; i < newMessages.length; i++) {
          if (newMessages[i].isRead != _messages[i].isRead ||
              newMessages[i].isDelivered != _messages[i].isDelivered ||
              newMessages[i].content != _messages[i].content ||
              newMessages[i].deletedForAll != _messages[i].deletedForAll ||
              newMessages[i].edited != _messages[i].edited) {
            needsUpdate = true;
            break;
          }
        }
      }

      if (needsUpdate) {
        final wasAtBottom = _scrollController.hasClients &&
            _scrollController.offset >=
                (_scrollController.position.maxScrollExtent - 50);

        setState(() => _messages = newMessages);

        if (wasAtBottom) _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final result = await ChatService.sendMessage(
      _conversation.id,
      content,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _messages.add(result['message'] as Message);
        _isSending = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isSending = false);
      _messageController.text = content;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;
    setState(() => _isFollowLoading = true);

    final result = await UserService.toggleFollow(_conversation.otherUserId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _conversation = _conversation.copyWith(
          isFollowing: result['data']['status'] == 'followed',
        );
        _isFollowLoading = false;
      });
    } else {
      setState(() => _isFollowLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Bloquer @${_conversation.otherUsername} ?'),
        content: const Text(
          'Cette personne ne pourra plus t\'envoyer de messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blocage à venir 🚧')),
    );
  }

  // ⏰ Formatage de l'heure
  String _formatMessageTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 30) {
      return 'maintenant';
    }

    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // 📅 Label du jour
  String _getDayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    if (diff < 7) return 'Il y a $diff jours';

    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];

    if (dt.year == now.year) {
      return '${dt.day} ${months[dt.month - 1]}';
    }
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 🌳 Icône de statut du message
  Widget _buildMessageStatus(Message msg) {
    if (msg.isRead) {
      return const BaobabCheckIcon(
        size: 12,
        color: Color(0xFFFFD600),
        count: 2,
      );
    } else if (msg.isDelivered) {
      return const BaobabCheckIcon(
        size: 12,
        color: Colors.white70,
        count: 2,
      );
    } else {
      return const BaobabCheckIcon(
        size: 12,
        color: Colors.white70,
        count: 1,
      );
    }
  }

  Widget _buildFollowBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu n\'es pas encore abonné à @${_conversation.otherUsername}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Suis-le ou bloque-le',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _isFollowLoading ? null : _toggleFollow,
            icon: _isFollowLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Suivre', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.green,
              backgroundColor: AppTheme.green.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: _blockUser,
            icon: const Icon(Icons.block, size: 16),
            label: const Text('Bloquer', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.gradient),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(
                _conversation.otherUsername.isNotEmpty
                    ? _conversation.otherUsername[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversation.otherUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Étudiant Baobab',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_conversation.isFollowing &&
              !_conversation.followsMe &&
              _conversation.otherUserId != _myUserId)
            _buildFollowBanner(),

          Expanded(child: _buildMessagesArea()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
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
              onPressed: _loadMessages,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waving_hand_outlined,
                size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Dis bonjour ! 👋',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final List<Widget> items = [];
    DateTime? previousDate;

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final msgDate = DateTime(
        msg.createdAt.year,
        msg.createdAt.month,
        msg.createdAt.day,
      );

      if (previousDate == null || !_isSameDay(previousDate, msgDate)) {
        items.add(_buildDateSeparator(msg.createdAt));
      }
      previousDate = msgDate;

      final isMe = msg.sender == _myUserId;
      items.add(_buildMessageBubble(msg, isMe));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildDateSeparator(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _getDayLabel(dt).toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555555),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    if (msg.deletedForAll) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Message supprimé',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(msg, isMe),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            gradient: isMe ? AppTheme.buttonGradient : null,
            color: isMe ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
                    child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ⬇️ FLÈCHE en haut à droite
              GestureDetector(
                onTap: () => _showMessageOptions(msg, isMe),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
              ),
              Text(
                msg.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.edited)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'modifié',
                        style: TextStyle(
                          color: isMe ? Colors.white60 : Colors.grey,
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Text(
                    _formatMessageTime(msg.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 5),
                    _buildMessageStatus(msg),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(Message msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copié 📋')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Transférer'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transfert à venir 🚧')),
                );
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(msg);
                },
              ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteForBothChoice(msg);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Supprimer pour moi',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteForMe(msg);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteForBothChoice(Message msg) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Pour qui veux-tu supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'me'),
            child: const Text('Pour moi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text(
              'Pour tout le monde',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (choice == 'me') {
      await _deleteForMe(msg);
    } else if (choice == 'all') {
      await _deleteForAll(msg);
    }
  }

  Future<void> _deleteForMe(Message msg) async {
    final result = await ChatService.deleteMessage(msg.id, scope: 'me');
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _messages.removeWhere((m) => m.id == msg.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message supprimé pour toi ✅')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

    Future<void> _deleteForAll(Message msg) async {
    final result = await ChatService.deleteMessage(msg.id, scope: 'all');
    if (!mounted) return;

    if (result['success'] == true) {
      // Mise à jour locale immédiate → pas besoin de recharger
      setState(() {
        final index = _messages.indexWhere((m) => m.id == msg.id);
        if (index != -1) {
          _messages[index] = Message(
            id: msg.id,
            conversation: msg.conversation,
            sender: msg.sender,
            senderId: msg.senderId,
            senderUsername: msg.senderUsername,
            content: '',
            createdAt: msg.createdAt,
            isRead: msg.isRead,
            isDelivered: msg.isDelivered,
            deletedForAll: true,
            edited: msg.edited,
          );
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Message supprimé pour tout le monde ✅')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

  Future<void> _editMessage(Message msg) async {
    final controller = TextEditingController(text: msg.content);

    final newContent = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextField(
          controller: controller,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (newContent == null || newContent.isEmpty) return;

    final result = await ChatService.editMessage(msg.id, newContent);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == msg.id);
        if (index != -1) {
          _messages[index] = result['message'];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message modifié ✅')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erreur')),
      );
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppTheme.green),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Envoi de photos à venir 📸'),
                  ),
                );
              },
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.buttonGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}