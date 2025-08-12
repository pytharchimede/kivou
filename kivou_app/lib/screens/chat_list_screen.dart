import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/chat.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      // Rediriger proprement vers la page de connexion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/auth');
      });
      return const SizedBox.shrink();
    }
    final convs = ref.watch(chatConversationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussions'),
      ),
      body: convs.when(
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(chatConversationsProvider);
            await ref
                .read(chatConversationsProvider.future)
                .catchError((_) => <ChatConversation>[]);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _ConversationTile(conv: list[i]),
          ),
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
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider);
    final myId = (auth.user?['id'] as int?) ?? -1;
    final isProviderSide =
        (conv.providerOwnerUserId != null && conv.providerOwnerUserId == myId);
    final displayName = isProviderSide
        ? (conv.clientName.isNotEmpty ? conv.clientName : conv.peerName)
        : (conv.providerName.isNotEmpty ? conv.providerName : conv.peerName);
    final displayAvatar = isProviderSide
        ? (conv.clientAvatarUrl.isNotEmpty
            ? conv.clientAvatarUrl
            : conv.peerAvatarUrl)
        : (conv.providerAvatarUrl.isNotEmpty
            ? conv.providerAvatarUrl
            : conv.peerAvatarUrl);
    return InkWell(
      onTap: () => context.push('/chat/${conv.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage:
                  displayAvatar.isNotEmpty ? NetworkImage(displayAvatar) : null,
              child: displayAvatar.isEmpty
                  ? Icon(
                      isProviderSide ? Icons.person : Icons.storefront_rounded)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (!isProviderSide && conv.clientName.isNotEmpty)
                    Text(
                      'Avec ${conv.clientName}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(conv.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (conv.unreadCount > 0)
              CircleAvatar(
                radius: 10,
                child: Text('${conv.unreadCount}',
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
