import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/chat.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convs = ref.watch(chatConversationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussions'),
      ),
      body: convs.when(
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) => _ConversationTile(conv: list[i]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final ChatConversation conv;
  const _ConversationTile({required this.conv});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
          backgroundImage: conv.peerAvatarUrl.isNotEmpty
              ? NetworkImage(conv.peerAvatarUrl)
              : null,
          child: conv.peerAvatarUrl.isEmpty ? const Icon(Icons.person) : null),
      title: Text(conv.peerName),
      subtitle:
          Text(conv.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: conv.unreadCount > 0
          ? CircleAvatar(
              radius: 10,
              child: Text('${conv.unreadCount}',
                  style: const TextStyle(fontSize: 12)))
          : null,
      onTap: () => context.go('/chat/${conv.id}'),
    );
  }
}
