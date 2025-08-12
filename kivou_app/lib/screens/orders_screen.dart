import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../services/booking_service.dart';
// import '../services/api_client.dart';

final ordersFutureProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final api = ref.read(apiClientProvider);
  final svc = BookingService(api);
  if (auth.isAuthenticated) {
    final userId = (auth.user?['id'] is int)
        ? auth.user!['id'] as int
        : int.tryParse((auth.user?['id'] ?? '').toString()) ?? 0;
    return await svc.listByUser(userId);
  }
  return <dynamic>[];
});

final ownerOrdersFutureProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final api = ref.read(apiClientProvider);
  final svc = BookingService(api);
  if (auth.isAuthenticated) {
    return await svc.listByOwner();
  }
  return <dynamic>[];
});

class OrdersScreen extends ConsumerWidget {
  final int initialIndex; // 0 = Demandeur, 1 = Prestataire
  const OrdersScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Commandes'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Accueil',
            onPressed: () => context.go('/home'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Demandeur'),
              Tab(text: 'Prestataire'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RequesterOrdersTab(),
            _OwnerOrdersTab(),
          ],
        ),
      ),
    );
  }
}

class _RequesterOrdersTab extends ConsumerWidget {
  const _RequesterOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(ordersFutureProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ordersFutureProvider);
        try {
          await ref.read(ordersFutureProvider.future);
        } catch (_) {}
      },
      child: future.when(
        data: (bookings) {
          final now = DateTime.now();
          final items = bookings.cast<Map<String, dynamic>>();
          final upcoming = items.where((b) {
            final dt =
                _BookingCard._parseDate((b['scheduled_at'] ?? '').toString());
            return dt == null || dt.isAfter(now);
          }).toList();
          final past = items.where((b) {
            final dt =
                _BookingCard._parseDate((b['scheduled_at'] ?? '').toString());
            return dt != null && dt.isBefore(now);
          }).toList();
          if (items.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('Aucune commande')),
            ]);
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(title: 'À venir'),
                const SizedBox(height: 8),
                ...List.generate(
                    upcoming.length,
                    (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(booking: upcoming[i]),
                        )),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(title: 'Passées'),
                const SizedBox(height: 8),
                ...List.generate(
                    past.length,
                    (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(booking: past[i]),
                        )),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _OwnerOrdersTab extends ConsumerWidget {
  const _OwnerOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(ownerOrdersFutureProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ownerOrdersFutureProvider);
        try {
          await ref.read(ownerOrdersFutureProvider.future);
        } catch (_) {}
      },
      child: future.when(
        data: (bookings) => bookings.isEmpty
            ? ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('Aucune commande à traiter')),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final b = bookings[i] as Map<String, dynamic>;
                  return _OwnerBookingCard(booking: b);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final df = DateFormat('EEE d MMM yyyy • HH:mm', 'fr');

    final service = (booking['service_category'] ?? 'Service').toString();
    final desc = (booking['service_description'] ?? '').toString();
    final status = (booking['status'] ?? 'pending').toString();
    final scheduledAtStr = (booking['scheduled_at'] ?? '').toString();
    final createdAtStr = (booking['created_at'] ?? '').toString();
    final duration = _toDouble(booking['duration']);
    final total = _toDouble(booking['total_price']);

    final DateTime? scheduledAt = _parseDate(scheduledAtStr);
    final DateTime? createdAt = _parseDate(createdAtStr);

    // Affiche le prestataire (nom + photo) côté demandeur
    final provider = booking['provider'] is Map<String, dynamic>
        ? booking['provider'] as Map<String, dynamic>
        : null;
    final avatarUrl = (provider?['photo_url'] ?? '').toString();
    final displayName = (provider?['name'] ?? 'Prestataire').toString();

    final st = _StatusStyle.from(status, theme);
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.08),
        theme.colorScheme.secondary.withValues(alpha: 0.06)
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(name: displayName, url: avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(
                              text: st.label,
                              color: st.bg,
                              textColor: st.fg,
                              icon: st.icon),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Planifié',
              value:
                  scheduledAt != null ? df.format(scheduledAt) : scheduledAtStr,
            ),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Durée',
              value: duration != null ? _formatHours(duration) : '-',
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Montant',
              value: total != null ? _formatMoney(total) : '-',
            ),
            if (createdAt != null || createdAtStr.isNotEmpty)
              _InfoRow(
                icon: Icons.history_toggle_off,
                label: 'Créée',
                value: createdAt != null ? df.format(createdAt) : createdAtStr,
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDetails(context),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Détails'),
                ),
                const SizedBox(width: 8),
                if (status == 'pending')
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Reprogrammer'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  static String _formatMoney(double v) {
    final f =
        NumberFormat.currency(locale: 'fr', symbol: 'F CFA', decimalDigits: 0);
    return f.format(v);
  }

  static String _formatHours(double hours) {
    if (hours < 1) {
      final mins = (hours * 60).round();
      return '$mins min';
    }
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }

  static double? _toDouble(dynamic x) {
    if (x == null) return null;
    if (x is num) return x.toDouble();
    return double.tryParse(x.toString());
  }

  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    // Supporte 'YYYY-MM-DD HH:MM:SS'
    try {
      if (s.contains('T')) return DateTime.tryParse(s);
      // Remplace espace par T pour ISO
      return DateTime.tryParse(s.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <MapEntry<String, String>>[
      MapEntry('Service', (booking['service_category'] ?? '').toString()),
      MapEntry(
          'Description', (booking['service_description'] ?? '').toString()),
      MapEntry('Statut', (booking['status'] ?? '').toString()),
      MapEntry('Planifié', (booking['scheduled_at'] ?? '').toString()),
      MapEntry('Durée', (booking['duration'] ?? '').toString()),
      MapEntry('Montant', (booking['total_price'] ?? '').toString()),
      MapEntry('Créée', (booking['created_at'] ?? '').toString()),
      if (booking['id'] != null) MapEntry('ID', booking['id'].toString()),
      if (booking['provider_id'] != null)
        MapEntry('Prestataire', booking['provider_id'].toString()),
      if (booking['user_id'] != null)
        MapEntry('Demandeur', booking['user_id'].toString()),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined),
                    const SizedBox(width: 8),
                    Text('Détails de la commande',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 110,
                              child: Text(e.key,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: theme.hintColor))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value.isEmpty ? '-' : e.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemCount: entries.length,
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

class _StatusStyle {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  _StatusStyle(this.label, this.bg, this.fg, this.icon);

  static _StatusStyle from(String status, ThemeData theme) {
    switch (status) {
      case 'confirmed':
        return _StatusStyle('Confirmée', Colors.green.withValues(alpha: 0.12),
            Colors.green.shade700, Icons.verified_outlined);
      case 'cancelled':
        return _StatusStyle('Annulée', Colors.red.withValues(alpha: 0.12),
            Colors.red.shade700, Icons.cancel_outlined);
      case 'completed':
        return _StatusStyle('Terminée', Colors.blue.withValues(alpha: 0.12),
            Colors.blue.shade700, Icons.check_circle_outline);
      default:
        return _StatusStyle('En attente', Colors.amber.withValues(alpha: 0.16),
            Colors.orange.shade700, Icons.hourglass_bottom_rounded);
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData icon;
  const _StatusPill(
      {required this.text,
      required this.color,
      required this.textColor,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: theme.colorScheme.primary.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.8))),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String url;
  const _Avatar({required this.name, required this.url});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
    final initials = name.trim().isEmpty
        ? 'U'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: bg,
          backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
          child: url.isEmpty
              ? Text(initials,
                  style: const TextStyle(fontWeight: FontWeight.bold))
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)
              ],
            ),
            child: const Icon(Icons.person, size: 10),
          ),
        )
      ],
    );
  }
}

class _OwnerBookingCard extends ConsumerWidget {
  final Map<String, dynamic> booking;
  const _OwnerBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final df = DateFormat('EEE d MMM yyyy • HH:mm', 'fr');

    final service = (booking['service_category'] ?? 'Service').toString();
    final desc = (booking['service_description'] ?? '').toString();
    final status = (booking['status'] ?? 'pending').toString();
    final scheduledAtStr = (booking['scheduled_at'] ?? '').toString();
    final duration = _BookingCard._toDouble(booking['duration']);
    final total = _BookingCard._toDouble(booking['total_price']);
    final DateTime? scheduledAt = _BookingCard._parseDate(scheduledAtStr);

    final requesterName = (booking['user_name'] ?? 'Demandeur').toString();
    final requesterAvatar = (booking['user_avatar_url'] ?? '').toString();

    final st = _StatusStyle.from(status, theme);
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.08),
        theme.colorScheme.secondary.withValues(alpha: 0.06)
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(name: requesterName, url: requesterAvatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              requesterName,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(
                              text: st.label,
                              color: st.bg,
                              textColor: st.fg,
                              icon: st.icon),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Date/heure',
              value:
                  scheduledAt != null ? df.format(scheduledAt) : scheduledAtStr,
            ),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Durée',
              value:
                  duration != null ? _BookingCard._formatHours(duration) : '-',
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Montant',
              value: total != null ? _BookingCard._formatMoney(total) : '-',
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showOwnerDetails(context),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Détails'),
                ),
                const SizedBox(width: 8),
                if (status == 'pending') ...[
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(ref, context, 'cancelled'),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _updateStatus(ref, context, 'confirmed'),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Valider'),
                  ),
                ] else if (status == 'confirmed') ...[
                  FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Confirmée'),
                  ),
                ] else if (status == 'cancelled') ...[
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.block),
                    label: const Text('Refusée'),
                  ),
                ] else if (status == 'completed') ...[
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Terminée'),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showOwnerDetails(BuildContext context) {
    _BookingCard(booking: booking)._showDetails(context);
  }

  Future<void> _updateStatus(
      WidgetRef ref, BuildContext context, String status) async {
    try {
      final api = ref.read(apiClientProvider);
      await BookingService(api).updateStatus(
          bookingId: int.tryParse(booking['id']?.toString() ?? '') ?? 0,
          status: status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Commande ${status == 'confirmed' ? 'confirmée' : 'refusée'}')));
      }
      ref.invalidate(ownerOrdersFutureProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.segment, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
