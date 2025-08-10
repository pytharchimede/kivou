import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_providers.dart';
import '../models/service_provider.dart';
import '../services/mappers.dart';

class ProviderDetailScreen extends ConsumerWidget {
  final String providerId;
  const ProviderDetailScreen({super.key, required this.providerId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Essayer depuis la liste distante déjà chargée
    final remote = ref.watch(remoteProvidersFutureProvider);
    ServiceProvider? candidate;
    remote.when(
      data: (list) {
        try {
          candidate = list.firstWhere((p) => p.id == providerId);
        } catch (_) {}
      },
      loading: () {},
      error: (_, __) {},
    );
    // 2) Fallback éventuel local
    candidate ??= ref.watch(providerByIdProvider(providerId));
    if (candidate != null) {
      return _ProviderDetailScaffold(provider: candidate!);
    }

    // 3) Fallback API: récupérer le détail par ID
    final providerSvc = ref.read(providerServiceProvider);
    final pid = int.tryParse(providerId) ?? 0;
    return FutureBuilder<Map<String, dynamic>>(
      future: providerSvc.detail(pid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Prestataire')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Prestataire')),
            body: const Center(child: Text('Prestataire introuvable')),
          );
        }
        final prov = providerFromApi(snap.data!);
        return _ProviderDetailScaffold(provider: prov);
      },
    );
  }
}

class _ProviderDetailScaffold extends StatelessWidget {
  final ServiceProvider provider;
  const _ProviderDetailScaffold({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: provider.photoUrl.isNotEmpty
                  ? Image.network(
                      provider.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.image, size: 48)),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.person, size: 64)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStars(provider.rating),
                      const SizedBox(width: 8),
                      Text('(${provider.reviewsCount})'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            '${provider.pricePerHour.toStringAsFixed(0)} FCFA/h'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (provider.categories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: -8,
                      children: provider.categories
                          .map((c) => Chip(label: Text(c)))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    provider.description.isEmpty
                        ? 'Pas de description.'
                        : provider.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text(
                              'Horaires: ${provider.workingHours.start} - ${provider.workingHours.end}'),
                          subtitle: Text(_formatDays(provider.availableDays)),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text(_displayPhone(provider.phone)),
                        ),
                      ],
                    ),
                  ),
                  if (provider.gallery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Galerie',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.gallery.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final url = provider.gallery[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 140,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 140,
                                height: 100,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final tel =
                        Uri.parse('tel:${_sanitizePhone(provider.phone)}');
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
                  onPressed: () =>
                      GoRouter.of(context).go('/booking/${provider.id}'),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Commander'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDays(List<String> days) {
    if (days.isEmpty) return 'Jours non précisés';
    // Affiche simplement la liste séparée par des virgules
    return days.join(', ');
  }

  String _displayPhone(String phone) => phone.isEmpty ? 'Non renseigné' : phone;

  String _sanitizePhone(String phone) {
    final raw = phone.isEmpty ? '+2250700000000' : phone;
    return raw.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  Widget _buildStars(double rating) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      children: [
        for (int i = 0; i < full; i++)
          const Icon(Icons.star, size: 18, color: Colors.amber),
        if (hasHalf) const Icon(Icons.star_half, size: 18, color: Colors.amber),
        for (int i = 0; i < (hasHalf ? 4 - full : 5 - full); i++)
          const Icon(Icons.star_border, size: 18, color: Colors.amber),
      ],
    );
  }
}
