import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/mappers.dart';
import '../services/booking_service.dart';
import '../widgets/booking_sheet.dart';

import '../models/announcement.dart';
import '../providers/app_providers.dart';
// chat_service import non requis ici, on passe par les providers

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String? _type; // request|offer
  String? _authorRole; // client|provider
  bool _loading = true;
  List<Announcement> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref
          .read(announcementServiceProvider)
          .list(type: _type, authorRole: _authorRole);
      setState(() => _items = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _contact(Announcement a) async {
    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated) {
      if (mounted) context.go('/auth');
      return;
    }
    // Ouvrir ou créer une conversation avec le publisher
    final conv = await ref.read(chatServiceProvider).openOrCreate(
          peerUserId: a.publisherUserId,
          providerId: a.providerId,
        );
    // Envoyer un message épinglé avec détails de l'annonce
    final text =
        '${a.type == 'request' ? 'Demande' : 'Offre'}: ${a.title}\n${a.description}${a.price != null ? '\nPrix: ${a.price} FCFA' : ''}';
    String? thumb = a.images.isNotEmpty ? a.images.first : null;
    await ref.read(chatServiceProvider).send(
          conversationId: conv.id,
          body: text,
          attachmentUrl: thumb,
          isPinned: true,
        );
    if (mounted) context.push('/chat/${conv.id}');
  }

  Future<void> _order(Announcement a) async {
    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated) {
      if (mounted) context.go('/auth');
      return;
    }
    if (a.providerId == null || a.providerId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cette annonce n\'est pas liée à un prestataire.')),
        );
      }
      return;
    }
    try {
      final userId = (auth.user?['id'] as int?) ?? 0;
      final providerId = int.tryParse(a.providerId!) ?? 0;
      final input = await showBookingSheet(
        context: context,
        serviceCategory: a.title,
        initialNotes: a.description.isEmpty ? null : a.description,
        initialDurationHours: 1.0,
        initialDateTime: DateTime.now().add(const Duration(hours: 1)),
        pricePerHour: null,
      );
      if (input == null) return;
      final scheduledAt = input.scheduledAt;
      final duration = input.durationHours;
      final total = a.price ?? 0.0;
      await BookingService(ref.read(apiClientProvider)).create(
        userId: userId,
        providerId: providerId,
        serviceCategory: input.serviceCategory,
        description: input.notes,
        scheduledAt: scheduledAt,
        duration: duration,
        totalPrice: total,
      );
      // Best-effort: notifier le propriétaire du prestataire
      try {
        await ref.read(notificationServiceProvider).create(
              title: 'Nouvelle commande',
              body: 'Sur votre annonce: ${a.title}',
              providerId: providerId,
            );
        // Rafraîchir le compteur des commandes en attente (côté owner)
        await ref.read(ownerPendingCountProvider.notifier).refresh();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Commande créée.')));
      // Optionnel: rediriger vers mes commandes
      // if (mounted) context.go('/orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces'),
        actions: [
          IconButton(
            tooltip: 'Publier',
            onPressed: () => context.push('/announcements/new'),
            icon: const Icon(Icons.add_circle_rounded),
          )
        ],
      ),
      body: Column(
        children: [
          _Filters(
            type: _type,
            authorRole: _authorRole,
            onChange: (t, r) {
              setState(() {
                _type = t;
                _authorRole = r;
              });
              _load();
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (c, i) => _Card(
                        item: _items[i],
                        onContact: () => _contact(_items[i]),
                        onOrder: () => _order(_items[i]),
                        onViewImages: _items[i].images.length > 1
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AnnouncementGalleryScreen(
                                      images: _items[i]
                                          .images
                                          .map(normalizeImageUrl)
                                          .toList(),
                                      title: _items[i].title,
                                    ),
                                  ),
                                )
                            : null,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _items.length,
                    ),
                  ),
          )
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final String? type;
  final String? authorRole;
  final void Function(String?, String?) onChange;
  const _Filters(
      {required this.type, required this.authorRole, required this.onChange});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          _ChipSelect(
            label: 'Toutes',
            selected: type == null,
            onTap: () => onChange(null, authorRole),
          ),
          const SizedBox(width: 6),
          _ChipSelect(
            label: 'Demandes',
            selected: type == 'request',
            onTap: () => onChange('request', authorRole),
          ),
          const SizedBox(width: 6),
          _ChipSelect(
            label: 'Offres',
            selected: type == 'offer',
            onTap: () => onChange('offer', authorRole),
          ),
          const Spacer(),
          PopupMenuButton<String?>(
            tooltip: 'Émetteur',
            onSelected: (v) => onChange(type, v),
            itemBuilder: (c) => [
              const PopupMenuItem(value: null, child: Text('Tous')),
              const PopupMenuItem(value: 'client', child: Text('Clients')),
              const PopupMenuItem(
                  value: 'provider', child: Text('Prestataires')),
            ],
            child: Chip(
              label: Text(authorRole == null
                  ? 'Tous'
                  : (authorRole == 'client' ? 'Clients' : 'Prestataires')),
            ),
          )
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Announcement item;
  final VoidCallback onContact;
  final VoidCallback? onOrder;
  final VoidCallback? onViewImages;
  const _Card(
      {required this.item,
      required this.onContact,
      this.onOrder,
      this.onViewImages});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onContact,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        (item.publisherAvatarUrl?.isNotEmpty ?? false)
                            ? NetworkImage(
                                normalizeImageUrl(item.publisherAvatarUrl!))
                            : null,
                    child: (item.publisherAvatarUrl?.isEmpty ?? true)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.publisherName,
                            style: theme.textTheme.titleMedium),
                        Text(
                          item.type == 'request' ? 'Demande' : 'Offre',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  if (item.price != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${item.price!.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (item.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: InkWell(
                      onTap: onViewImages,
                      child: CachedNetworkImage(
                        imageUrl: normalizeImageUrl(item.images.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                if (item.images.length > 1) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (c, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: normalizeImageUrl(item.images[i]),
                          width: 96,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemCount: item.images.length,
                    ),
                  )
                ]
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('Contacter'),
                  ),
                  const SizedBox(width: 8),
                  if (onOrder != null)
                    FilledButton.icon(
                      onPressed: onOrder,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Commander'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Partager'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AnnouncementGalleryScreen extends StatelessWidget {
  final List<String> images;
  final String title;
  const AnnouncementGalleryScreen(
      {super.key, required this.images, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PageView.builder(
        itemCount: images.length,
        itemBuilder: (c, i) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipSelect extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipSelect(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
          color: selected ? theme.colorScheme.onPrimaryContainer : null),
    );
  }
}
