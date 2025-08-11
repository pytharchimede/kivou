class ChatConversation {
  final int id;
  final int peerUserId; // l'interlocuteur (prestataire ou client)
  final String peerName;
  final String peerAvatarUrl;
  final String lastMessage;
  final DateTime lastAt;
  final int unreadCount;
  final String? providerId; // optionnel pour relier au prestataire

  ChatConversation({
    required this.id,
    required this.peerUserId,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.lastMessage,
    required this.lastAt,
    required this.unreadCount,
    this.providerId,
  });

  factory ChatConversation.fromApi(Map<String, dynamic> j) {
    return ChatConversation(
      id: int.tryParse(j['id']?.toString() ?? '') ?? (j['id'] ?? 0),
      peerUserId: int.tryParse(j['peer_user_id']?.toString() ?? '') ?? 0,
      peerName: j['peer_name']?.toString() ?? 'Utilisateur',
      peerAvatarUrl: j['peer_avatar_url']?.toString() ?? '',
      lastMessage: j['last_message']?.toString() ?? '',
      lastAt:
          DateTime.tryParse(j['last_at']?.toString() ?? '') ?? DateTime.now(),
      unreadCount: int.tryParse(j['unread_count']?.toString() ?? '0') ?? 0,
      providerId: j['provider_id']?.toString(),
    );
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int fromUserId;
  final int toUserId;
  final String body;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.fromUserId,
    required this.toUserId,
    required this.body,
    required this.createdAt,
  });

  bool isMine(int myUserId) => fromUserId == myUserId;

  factory ChatMessage.fromApi(Map<String, dynamic> j) {
    return ChatMessage(
      id: int.tryParse(j['id']?.toString() ?? '') ?? (j['id'] ?? 0),
      conversationId: int.tryParse(j['conversation_id']?.toString() ?? '') ?? 0,
      fromUserId: int.tryParse(j['from_user_id']?.toString() ?? '') ?? 0,
      toUserId: int.tryParse(j['to_user_id']?.toString() ?? '') ?? 0,
      body: j['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
