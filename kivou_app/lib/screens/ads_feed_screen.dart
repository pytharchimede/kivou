import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../services/ads_service.dart';
import '../services/mappers.dart';
import '../models/ad.dart';
import '../models/chat.dart';

final adsServiceProvider =
    Provider<AdsService>((ref) => AdsService(ref.read(apiClientProvider)));
final adsFeedProvider = FutureProvider.autoDispose<List<Ad>>((ref) async {
  final svc = ref.read(adsServiceProvider);
  return svc.list(status: 'active');
});

class AdsFeedScreen extends ConsumerStatefulWidget {
  const AdsFeedScreen({super.key});
  @override
  ConsumerState<AdsFeedScreen> createState() => _AdsFeedScreenState();
}

class _AdsFeedScreenState extends ConsumerState<AdsFeedScreen> {
  String _kind = 'all'; // all | request | offer
  final _searchCtrl = TextEditingController();
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(adsFeedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('KIVOU'),
        actions: [
          IconButton(
            onPressed: () => context.go('/home-providers'),
            tooltip: 'Prestataires',
            icon: const Icon(Icons.store_mall_directory_outlined),
          ),
          _BellButton(),
          _ChatsWithBadgeButton(),
          IconButton(
              onPressed: () => context.go('/orders'),
              icon: const Icon(Icons.receipt_long)),
          const _ProfileWithBadgeButton(),
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: _FiltersBar(
                kind: _kind,
                onKindChanged: (v) {
                  setState(() => _kind = v);
                  _refreshWithFilters();
                },
                onSearch: (q) {
                  _refreshWithFilters();
                },
                searchController: _searchCtrl,
              )),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _AdCard(ad: _applyFilters(list)[i]),
                  childCount: _applyFilters(list).length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
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

extension on _AdsFeedScreenState {
  List<Ad> _applyFilters(List<Ad> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return list.where((a) {
      final okKind = (_kind == 'all') || (a.kind == _kind);
      if (!okKind) return false;
      if (q.isEmpty) return true;
      final inTitle = a.title.toLowerCase().contains(q);
      final inDesc = a.description.toLowerCase().contains(q);
      return inTitle || inDesc;
    }).toList();
  }

  void _refreshWithFilters() {
    // Ici on invalide et laisse le filtre s'appliquer côté client.
    // Si nécessaire plus tard: appeler AdsService.list(kind: _kind!='all'?_kind:null, q: _searchCtrl.text)
    ref.invalidate(adsFeedProvider);
  }
}

class _FiltersBar extends StatelessWidget {
  final String kind; // all | request | offer
  final void Function(String) onKindChanged;
  final void Function(String) onSearch;
  final TextEditingController searchController;
  const _FiltersBar(
      {required this.kind,
      required this.onKindChanged,
      required this.onSearch,
      required this.searchController});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                _Choice(
                    kind: 'all',
                    label: 'Tous',
                    selected: kind == 'all',
                    onTap: () => onKindChanged('all')),
                const SizedBox(width: 8),
                _Choice(
                    kind: 'request',
                    label: 'Demandes',
                    selected: kind == 'request',
                    onTap: () => onKindChanged('request')),
                const SizedBox(width: 8),
                _Choice(
                    kind: 'offer',
                    label: 'Offres',
                    selected: kind == 'offer',
                    onTap: () => onKindChanged('offer')),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: onSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher une annonce…',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String kind;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice(
      {required this.kind,
      required this.label,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check,
                  size: 16, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                )),
          ],
        ),
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
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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

class _ProfileWithBadgeButton extends ConsumerWidget {
  const _ProfileWithBadgeButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(ownerPendingCountProvider);
    // Charger au premier affichage (best effort)
    ref.read(ownerPendingCountProvider.notifier).refresh();
    return Stack(
      children: [
        IconButton(
          onPressed: () => GoRouter.of(context).go('/profile'),
          icon: const Icon(Icons.person),
          tooltip: 'Profil',
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _BellButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);
    final hasUnread = items.isNotEmpty; // simplifié: tout est non lu
    return Stack(
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(context, ref),
        ),
        if (hasUnread)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    // Charger depuis l'API si connecté
    ref.read(notificationsProvider.notifier).load();
    final items = ref.read(notificationsProvider);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications),
                    const SizedBox(width: 8),
                    const Text('Notifications',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          ref.read(notificationsProvider.notifier).clear(),
                      child: const Text('Vider'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Aucune notification')),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        return ListTile(
                          leading:
                              const Icon(Icons.notifications_active_outlined),
                          title: Text(it['title'] ?? ''),
                          subtitle: Text(it['body'] ?? ''),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatsWithBadgeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final convs = ref.watch(chatConversationsProvider).maybeWhen(
          data: (list) => list,
          orElse: () => <ChatConversation>[],
        );
    final int totalUnread =
        convs.map((c) => c.unreadCount).fold<int>(0, (prev, el) => prev + el);
    final hasUnread = totalUnread > 0;
    return Stack(
      children: [
        IconButton(
          onPressed: () {
            if (!auth.isAuthenticated) {
              GoRouter.of(context).go('/auth');
            } else {
              GoRouter.of(context).push('/chats');
            }
          },
          tooltip: 'Discussions',
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        if (hasUnread)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                totalUnread > 99 ? '99+' : '$totalUnread',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
