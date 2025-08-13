import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../services/booking_service.dart';
import '../services/mappers.dart';

final ordersFutureProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final api = ref.read(apiClientProvider);
  final svc = BookingService(api);
  if (auth.isAuthenticated) {
    final userId = (auth.user?['id'] is int)
        ? auth.user!['id'] as int
        : int.tryParse((auth.user?['id'] ?? '').toString()) ?? 0;
    return await svc.listByUser(userId); // Commandes émises par l'utilisateur
  }
  return <dynamic>[];
});

class OrdersScreen extends ConsumerStatefulWidget {
  final int? initialIndex; // conservé pour compat compatibilité ancienne route
  const OrdersScreen({super.key, this.initialIndex});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(ordersFutureProvider);
    try {
      await ref.read(ordersFutureProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncOrders = ref.watch(ordersFutureProvider);
    final loading = asyncOrders.isLoading;
    final orders = asyncOrders.maybeWhen(
      data: (v) => v.cast<Map<String, dynamic>>(),
      orElse: () => const <Map<String, dynamic>>[],
    );

    // Filtrage simple
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? orders
        : orders.where((o) {
            bool match(String? s) => (s ?? '').toLowerCase().contains(q);
            return match(o['service_category']?.toString()) ||
                match(o['service_description']?.toString()) ||
                match(o['description']?.toString()) ||
                match(o['notes']?.toString()) ||
                match(o['provider_name']?.toString()) ||
                match(o['status']?.toString()) ||
                match(o['id']?.toString());
          }).toList();

    List<Widget> listChildren;
    if (loading && orders.isEmpty) {
      listChildren = [
        const SizedBox(height: 12),
        ...List.generate(
            6,
            (i) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _OrderSkeletonCard(),
                )),
      ];
    } else if (filtered.isEmpty) {
      listChildren = const [
        SizedBox(height: 140),
        Center(child: Text('Aucune commande')),
      ];
    } else {
      listChildren = [
        const SizedBox(height: 8),
        ...List.generate(
          filtered.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SentBookingCard(booking: filtered[i]),
          ),
        ),
        const SizedBox(height: 32),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes émises'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
        bottom: loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Rechercher (service, prestataire, statut, id...)',
                filled: true,
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: listChildren,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Anciennes vues par onglets supprimées au profit d'un filtre en haut de page.

class _SentBookingCard extends ConsumerWidget {
  final Map<String, dynamic> booking;
  const _SentBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final df = DateFormat('EEE d MMM yyyy • HH:mm', 'fr');

    final service = (booking['service_category'] ?? 'Service').toString();
    final desc = (booking['service_description'] ??
            booking['description'] ??
            booking['notes'] ??
            '')
        .toString();
    final status = (booking['status'] ?? 'pending').toString();
    final scheduledAtStr = (booking['scheduled_at'] ?? '').toString();
    final createdAtStr = (booking['created_at'] ?? '').toString();
    final duration = _Util.toDouble(booking['duration']);
    final total = _Util.toDouble(booking['total_price']);
    final DateTime? scheduledAt = _Util.parseDate(scheduledAtStr);
    final DateTime? createdAt = _Util.parseDate(createdAtStr);

    final requesterName =
        (booking['user_name'] ?? booking['user_id'] ?? 'Moi').toString();
    final requesterAvatar = normalizeImageUrl(
        (booking['user_avatar_url'] ?? booking['avatar_url'] ?? '').toString());
    final providerName = (booking['provider_name'] ?? 'Prestataire').toString();
    final providerAvatar =
        normalizeImageUrl((booking['provider_photo_url'] ?? '').toString());

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(name: requesterName, url: requesterAvatar),
                    const SizedBox(height: 6),
                    Text('Moi', style: theme.textTheme.labelSmall),
                  ],
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(name: providerName, url: providerAvatar),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    providerName,
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
                            const SizedBox(height: 4),
                            Text(
                              service,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(desc,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis),
            ],
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
              value: duration != null ? _Util.formatHours(duration) : '-',
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Montant',
              value: total != null ? _Util.formatMoney(total) : '-',
            ),
            if (createdAt != null || createdAtStr.isNotEmpty)
              _InfoRow(
                icon: Icons.history_toggle_off,
                label: 'Créée',
                value: createdAt != null ? df.format(createdAt) : createdAtStr,
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showDetails(context),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Détails'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <MapEntry<String, String>>[
      MapEntry('Service', (booking['service_category'] ?? '').toString()),
      MapEntry(
          'Description',
          (booking['service_description'] ??
                  booking['description'] ??
                  booking['notes'] ??
                  '')
              .toString()),
      MapEntry('Statut', (booking['status'] ?? '').toString()),
      MapEntry('Planifié', (booking['scheduled_at'] ?? '').toString()),
      MapEntry('Durée', (booking['duration'] ?? '').toString()),
      MapEntry('Montant', (booking['total_price'] ?? '').toString()),
      MapEntry('Créée', (booking['created_at'] ?? '').toString()),
      if (booking['id'] != null) MapEntry('ID', booking['id'].toString()),
      if (booking['provider_id'] != null)
        MapEntry('Prestataire', booking['provider_id'].toString()),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
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
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(e.key,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(e.value.isEmpty ? '-' : e.value,
                              style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Util {
  static String formatMoney(double v) {
    final f =
        NumberFormat.currency(locale: 'fr', symbol: 'F CFA', decimalDigits: 0);
    return f.format(v);
  }

  static String formatHours(double hours) {
    if (hours < 1) {
      final mins = (hours * 60).round();
      return '$mins min';
    }
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }

  static double? toDouble(dynamic x) {
    if (x == null) return null;
    if (x is num) return x.toDouble();
    return double.tryParse(x.toString());
  }

  static DateTime? parseDate(String s) {
    if (s.isEmpty) return null;
    try {
      if (s.contains('T')) return DateTime.tryParse(s);
      return DateTime.tryParse(s.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
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

// Suppression de la carte propriétaire avec actions; remplacée par _SentBookingCard.

// _SectionHeader supprimé (plus utilisé).

class _OrderSkeletonCard extends StatelessWidget {
  const _OrderSkeletonCard();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // avatar demandeur
                _Shimmer(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: base,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SkeletonLine(widthFactor: 0.5, height: 16),
                      SizedBox(height: 6),
                      _SkeletonLine(widthFactor: 0.8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _SkeletonLine(widthFactor: 0.6),
            const SizedBox(height: 6),
            const _SkeletonLine(widthFactor: 0.4),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;
  const _SkeletonLine({this.widthFactor = 1.0, this.height = 12});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: _Shimmer(
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = base.withValues(alpha: 0.5);
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final grad = LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.25, 0.5, 0.75],
          begin: Alignment(-1 + _anim.value, 0),
          end: Alignment(1 + _anim.value, 0),
        );
        return ShaderMask(
          shaderCallback: (rect) => grad.createShader(rect),
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
