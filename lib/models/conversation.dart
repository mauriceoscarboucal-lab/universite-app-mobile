class Conversation {
  final int id;
  final int otherUserId;
  final String otherUsername;
  final String? otherPhoto;
  final String? lastMessage;
  final int? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime updatedAt;
  final bool isFollowing;      // <-- NOUVEAU
  final bool followsMe;        // <-- NOUVEAU
  final bool lastMessageIsRead;        // <-- AJOUTE
  final bool lastMessageIsDelivered;   // <-- AJOUTE

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    this.otherPhoto,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.updatedAt,
    this.isFollowing = false,
    this.followsMe = false,
    this.lastMessageIsRead = false,        // <-- AJOUTE
    this.lastMessageIsDelivered = false,   // <-- AJOUTE
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['last_message'];
    return Conversation(
      id: json['id'],
      otherUserId: json['other_user_id'],
      otherUsername: json['other_username'] ?? '',
      otherPhoto: json['other_photo'],
      lastMessage: lastMsg != null ? lastMsg['content'] : null,
      lastMessageSenderId: lastMsg != null ? lastMsg['sender_id'] : null,
      lastMessageAt: lastMsg != null
          ? DateTime.parse(lastMsg['created_at'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
      isFollowing: json['is_following'] ?? false,
      followsMe: json['follows_me'] ?? false,
      lastMessageIsRead: lastMsg != null ? (lastMsg['is_read'] ?? false) : false,               // <-- AJOUTE
      lastMessageIsDelivered: lastMsg != null ? (lastMsg['is_delivered'] ?? false) : false,     // <-- AJOUTE
    );
  }

  /// Renvoie une copie modifiée
  Conversation copyWith({
    bool? isFollowing,
    bool? followsMe,
  }) {
    return Conversation(
      id: id,
      otherUserId: otherUserId,
      otherUsername: otherUsername,
      otherPhoto: otherPhoto,
      lastMessage: lastMessage,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      updatedAt: updatedAt,
      isFollowing: isFollowing ?? this.isFollowing,
      followsMe: followsMe ?? this.followsMe,
    );
  }
}

class Message {
  final int id;
  final int conversation;
  final int sender;
  final int senderId;
  final String senderUsername;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final bool isDelivered;
  final bool deletedForAll;    // <-- AJOUTE
  final bool edited;           // <-- AJOUTE

  Message({
    required this.id,
    required this.conversation,
    required this.sender,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.isDelivered = false,
    this.deletedForAll = false,   // <-- AJOUTE
    this.edited = false,          // <-- AJOUTE
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversation: json['conversation'],
      sender: json['sender'],
      senderId: json['sender_id'] ?? json['sender'],
      senderUsername: json['sender_username'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      isDelivered: json['is_delivered'] ?? false,
      deletedForAll: json['deleted_for_all'] ?? false,
      edited: json['edited'] ?? false,
    );
  }
}