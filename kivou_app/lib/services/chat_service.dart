import 'api_client.dart';
import '../models/chat.dart';

class ChatService {
  final ApiClient _api;
  ChatService(this._api);

  Future<List<ChatConversation>> listConversations() async {
    final list = await _api.getList('/api/chat/conversations.php');
    return list
        .map((e) => ChatConversation.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> listMessages(int conversationId) async {
    final list = await _api
        .getList('/api/chat/messages.php', {'conversation_id': conversationId});
    return list
        .map((e) => ChatMessage.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatConversation> openOrCreate(
      {required int peerUserId, String? providerId}) async {
    final data = await _api.postJson('/api/chat/open.php', {
      'peer_user_id': peerUserId,
      if (providerId != null) 'provider_id': providerId,
    });
    return ChatConversation.fromApi(data);
  }

  Future<ChatMessage> send(
      {required int conversationId, required String body}) async {
    final data = await _api.postJson('/api/chat/send.php', {
      'conversation_id': conversationId,
      'body': body,
    });
    return ChatMessage.fromApi(data);
  }

  Future<void> markRead(int conversationId) async {
    await _api.postJson(
        '/api/chat/mark_read.php', {'conversation_id': conversationId});
  }
}
