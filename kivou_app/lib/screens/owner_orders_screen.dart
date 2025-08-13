import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_providers.dart';
import '../services/booking_service.dart';
import '../services/mappers.dart';
import '../widgets/quick_call_sheet.dart';

class OwnerOrdersScreen extends ConsumerStatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen> {
  late final BookingService _svc;
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _svc = BookingService(ref.read(apiClientProvider));
    _future = _svc.listByOwner();
    // Synchroniser le badge au premier affichage
    Future.microtask(
        () => ref.read(ownerPendingCountProvider.notifier).refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _svc.listByOwner();
    });
    await _future;
    // Mettre à jour le badge global
    await ref.read(ownerPendingCountProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
          tooltip: 'Accueil',
        ),
        title: const Text('Commandes reçues'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Erreur: ${snap.error}'));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const Center(
                  child: Text('Aucune commande pour le moment.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = items[i] as Map<String, dynamic>;
                return _OwnerBookingCard(
                  data: b,
                  onAccept: () =>
                      _update((b['id'] as num).toInt(), 'confirmed'),
                  onReject: () =>
                      _update((b['id'] as num).toInt(), 'cancelled'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _update(int bookingId, String status) async {
    try {
      await BookingService(ref.read(apiClientProvider))
          .updateStatus(bookingId: bookingId, status: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(status == 'confirmed'
                ? 'Commande acceptée'
                : 'Commande refusée')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

class _OwnerBookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _OwnerBookingCard(
      {required this.data, required this.onAccept, required this.onReject});

  String _str(dynamic v) => v?.toString() ?? '';
  double? _numToDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Future<void> _openMaps(BuildContext context, double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir la carte.')));
    }
  }

  Color _statusColor(BuildContext ctx, String status) {
    final cs = Theme.of(ctx).colorScheme;
    switch (status) {
      case 'confirmed':
        return cs.primary;
      case 'cancelled':
        return Colors.redAccent;
      case 'completed':
        return Colors.green;
      default:
        return cs.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = data['id'] ?? '';
    final status =
        _str(data['status'].toString().isEmpty ? 'pending' : data['status']);
    final userName = _str(data['user_name'] ?? data['user_id']);
    final avatar = normalizeImageUrl(
        _str(data['user_avatar_url'] ?? data['avatar_url'] ?? ''));
    final phone = _str(data['user_phone'] ?? data['phone'] ?? '');
    final category = _str(data['service_category']);
    final when = _str(data['scheduled_at']);
    final duration = _numToDouble(data['duration']);
    final price = _numToDouble(data['total_price']);
    final description = _str(
        data['service_description'] ?? data['description'] ?? data['notes']);
    final address = _str(data['address'] ?? data['location'] ?? '');
    final lat = _numToDouble(data['lat'] ?? data['latitude']);
    final lng = _numToDouble(data['lng'] ?? data['longitude']);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(userName,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _statusColor(context, status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                color: _statusColor(context, status),
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (category.isNotEmpty)
                            Chip(
                                label: Text(category),
                                visualDensity: VisualDensity.compact),
                          if (when.isNotEmpty)
                            Chip(
                              label: Text(when),
                              avatar: const Icon(Icons.schedule, size: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (duration != null)
                            Chip(
                              label: Text(
                                  '${duration.toStringAsFixed(duration == duration.floorToDouble() ? 0 : 1)} h'),
                              avatar:
                                  const Icon(Icons.timer_outlined, size: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (price != null)
                            Chip(
                              label: Text('${price.toStringAsFixed(0)} FCFA'),
                              avatar:
                                  const Icon(Icons.payments_outlined, size: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (phone.isNotEmpty)
                  IconButton(
                    tooltip: 'Appel rapide',
                    onPressed: () => QuickCallSheet.show(context,
                        phoneNumber: phone, message: 'Bonjour $userName'),
                    icon: const Icon(Icons.call_rounded),
                  ),
              ],
            ),
          ),

          // Détails
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#$id',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Détails de la demande',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(description),
                ],
                if (address.isNotEmpty || (lat != null && lng != null)) ...[
                  const SizedBox(height: 10),
                  Text('Localisation',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  if (address.isNotEmpty) Text(address),
                  if (lat != null && lng != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _openMaps(context, lat, lng),
                        icon: const Icon(Icons.place_outlined),
                        label: const Text('Voir sur la carte'),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: OverflowBar(
              spacing: 8,
              overflowSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: status == 'pending' ? onReject : null,
                  icon: const Icon(Icons.close),
                  label: const Text('Refuser'),
                ),
                FilledButton.icon(
                  onPressed: status == 'pending' ? onAccept : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Accepter'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
