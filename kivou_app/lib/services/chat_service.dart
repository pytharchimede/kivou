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
      {required int conversationId,
      String? body,
      String? attachmentUrl,
      double? lat,
      double? lng}) async {
    final payload = <String, dynamic>{
      'conversation_id': conversationId,
      if (body != null) 'body': body,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
    };
    final data = await _api.postJson('/api/chat/send.php', payload);
    return ChatMessage.fromApi(data);
  }

  Future<void> markRead(int conversationId) async {
    await _api.postJson(
        '/api/chat/mark_read.php', {'conversation_id': conversationId});
  }
}
