import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_providers.dart';
import '../models/service_provider.dart';

class ProviderDetailScreen extends ConsumerWidget {
  final String providerId;
  const ProviderDetailScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try from remote cache first
    final remote = ref.watch(remoteProvidersFutureProvider);
    ServiceProvider? provider;
    remote.when(
      data: (list) {
        try {
          provider = list.firstWhere((p) => p.id == providerId);
        } catch (_) {}
      },
      loading: () {},
      error: (_, __) {},
    );
    provider ??= ref.watch(providerByIdProvider(providerId));
    if (provider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prestataire')),
        body: const Center(child: Text('Prestataire introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(provider!.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider!.description),
            const SizedBox(height: 12),
            Wrap(
                spacing: 8,
                children: provider!.categories
                    .map((c) => Chip(label: Text(c)))
                    .toList()),
            const Spacer(),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final tel = Uri.parse('tel:+2250700000000');
                    if (await canLaunchUrl(tel)) {
                      await launchUrl(tel);
                    }
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Appeler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/booking/${provider!.id}'),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Commander'),
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
