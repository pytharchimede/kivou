import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../services/booking_service.dart';
// import '../services/api_client.dart';

final ordersFutureProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final api = ref.read(apiClientProvider);
  final svc = BookingService(api);
  if (auth.isAuthenticated) {
    return await svc.listByUser(0);
  }
  return <dynamic>[];
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(ordersFutureProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Accueil',
          onPressed: () => context.go('/home'),
        ),
      ),
      body: future.when(
        data: (bookings) => bookings.isEmpty
            ? const Center(child: Text('Aucune commande'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final b = bookings[i];
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text(b['service_category'].toString()),
                    subtitle: Text(b['scheduled_at'].toString()),
                    trailing: Text(b['status'].toString()),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

// helper removed
