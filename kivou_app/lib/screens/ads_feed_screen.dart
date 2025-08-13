import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../services/ads_service.dart';
import '../services/mappers.dart';
import '../models/ad.dart';

final adsServiceProvider =
    Provider<AdsService>((ref) => AdsService(ref.read(apiClientProvider)));
final adsFeedProvider = FutureProvider.autoDispose<List<Ad>>((ref) async {
  final svc = ref.read(adsServiceProvider);
  return svc.list(status: 'active');
});

class AdsFeedScreen extends ConsumerWidget {
  const AdsFeedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(adsFeedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fil d'annonces"),
        actions: [
          IconButton(
            onPressed: () => context.go('/home-providers'),
            tooltip: 'Prestataires',
            icon: const Icon(Icons.store_mall_directory_outlined),
          ),
          IconButton(
            onPressed: () => context.go('/chats'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ads.when(
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adsFeedProvider);
            try {
              await ref.read(adsFeedProvider.future);
            } catch (_) {}
          },
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: list.length,
            itemBuilder: (ctx, i) => _AdCard(ad: list[i]),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ad-compose'),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Publier'),
      ),
    );
  }
}

class _AdCard extends ConsumerWidget {
  final Ad ad;
  const _AdCard({required this.ad});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final auth = ref.read(authStateProvider);
          if (!auth.isAuthenticated) {
            if (context.mounted) context.go('/auth');
            return;
          }
          final myId = (auth.user?['id'] as int?) ?? 0;
          if (myId == ad.authorUserId) return;
          final conv = await ref.read(chatServiceProvider).openOrCreate(
              peerUserId: ad.authorUserId, providerId: ad.providerId);
          try {
            await ref
                .read(adsServiceProvider)
                .pinInConversation(conversationId: conv.id, adId: ad.id);
          } catch (_) {}
          if (context.mounted) context.push('/chat/${conv.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _AdImage(url: ad.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: ad.authorAvatarUrl.isNotEmpty
                            ? NetworkImage(
                                normalizeImageUrl(ad.authorAvatarUrl))
                            : null,
                        child: ad.authorAvatarUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ad.authorName.isNotEmpty
                                  ? ad.authorName
                                  : (ad.authorType == 'provider'
                                      ? ad.providerName
                                      : 'Client'),
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              ad.kind == 'request' ? 'Demande' : 'Offre',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      if (ad.amount != null)
                        Chip(
                          label: Text(
                              '${ad.amount!.toStringAsFixed(0)} ${ad.currency}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ad.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ad.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        ad.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _AdImage extends StatelessWidget {
  final String url;
  const _AdImage({required this.url});
  @override
  Widget build(BuildContext context) {
    final u = normalizeImageUrl(url);
    if (u.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image, size: 32)),
      );
    }
    return Image.network(
      u,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
