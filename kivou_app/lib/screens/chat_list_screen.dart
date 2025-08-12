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
    final providerName =
        conv.providerName.isNotEmpty ? conv.providerName : conv.peerName;
    final providerAvatar = conv.providerAvatarUrl.isNotEmpty
        ? conv.providerAvatarUrl
        : conv.peerAvatarUrl;
    return InkWell(
      onTap: () => context.push('/chat/${conv.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: providerAvatar.isNotEmpty
                      ? NetworkImage(providerAvatar)
                      : null,
                  child: providerAvatar.isEmpty
                      ? const Icon(Icons.storefront_rounded)
                      : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.surface,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundImage: conv.clientAvatarUrl.isNotEmpty
                          ? NetworkImage(conv.clientAvatarUrl)
                          : null,
                      child: conv.clientAvatarUrl.isEmpty
                          ? const Icon(Icons.person, size: 14)
                          : null,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(providerName,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    conv.clientName.isNotEmpty
                        ? 'Client: ${conv.clientName}'
                        : conv.peerName,
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
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conv.unreadCount > 0)
                  CircleAvatar(
                    radius: 10,
                    child: Text('${conv.unreadCount}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                const SizedBox(height: 6),
                IconButton(
                  tooltip: 'Passer commande',
                  onPressed: () {
                    final pid = conv.providerId;
                    if (pid != null && pid.isNotEmpty) {
                      context.push('/booking/$pid');
                    }
                  },
                  icon: Icon(Icons.push_pin_rounded,
                      color: theme.colorScheme.primary),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
