import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../services/booking_service.dart';

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
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _svc.listByOwner();
    });
    await _future;
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
                final status = (b['status'] ?? 'pending') as String;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('#${b['id']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Chip(label: Text(status)),
                            const Spacer(),
                            Text('${b['total_price']} FCFA'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                            '${b['service_category'] ?? ''} - ${b['scheduled_at'] ?? ''}'),
                        const SizedBox(height: 6),
                        Text('Client: ${b['user_name'] ?? b['user_id']}',
                            style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: status == 'pending'
                                    ? () => _update(b['id'] as int, 'cancelled')
                                    : null,
                                icon: const Icon(Icons.close),
                                label: const Text('Refuser'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: status == 'pending'
                                    ? () => _update(b['id'] as int, 'confirmed')
                                    : null,
                                icon: const Icon(Icons.check),
                                label: const Text('Accepter'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
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
