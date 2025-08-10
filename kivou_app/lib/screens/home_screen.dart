import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/app_providers.dart';
import '../widgets/provider_card.dart';
import '../widgets/service_chip.dart';
import '../widgets/filter_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(remoteProvidersFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KIVOU'),
        actions: [
          IconButton(
              onPressed: () => context.go('/orders'),
              icon: const Icon(Icons.receipt_long)),
          IconButton(
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.person)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Champ de recherche
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un service, un prestataire…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => ref
                        .read(searchFiltersProvider.notifier)
                        .updateSearchQuery(v),
                  ),
                  const SizedBox(height: 12),
                  // Catégories
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final cat in const [
                          'Tous',
                          'Ménage',
                          'Plomberie',
                          'Électricité',
                          'Menuiserie',
                          'Informatique',
                          'Serrurerie',
                          'Peinture',
                          'Déménagement',
                          'Climatisation',
                          'Jardinage',
                        ])
                          ServiceChip(
                            label: cat,
                            selected:
                                ref.watch(searchFiltersProvider).category ==
                                    cat,
                            onTap: () => ref
                                .read(searchFiltersProvider.notifier)
                                .updateCategory(cat),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Carte réelle Google Maps centrée sur Abidjan - Koumassi
                  _KoumassiMap(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          providers.when(
            data: (list) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final p = list[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ProviderCard(
                      provider: p,
                      userLat: 5.35,
                      userLng: -4.02,
                    ),
                  );
                },
                childCount: list.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )),
            error: (e, st) => SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Erreur chargement: $e')),
            )),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await FilterSheet.show(context, child: const _FiltersContent());
        },
        label: const Text('Filtres'),
        icon: const Icon(Icons.filter_list),
      ),
    );
  }
}

class _FiltersContent extends ConsumerWidget {
  const _FiltersContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtres', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.place, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Distance max: ${filters.maxDistance.toStringAsFixed(1)} km'),
                Slider(
                  value: filters.maxDistance,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${filters.maxDistance.toStringAsFixed(0)} km',
                  onChanged: (v) => ref
                      .read(searchFiltersProvider.notifier)
                      .updateMaxDistance(v),
                ),
              ],
            ),
          ),
        ]),
        Row(children: [
          const Icon(Icons.star_rate_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note minimale: ${filters.minRating.toStringAsFixed(1)}'),
                Slider(
                  value: filters.minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: filters.minRating.toStringAsFixed(1),
                  onChanged: (v) => ref
                      .read(searchFiltersProvider.notifier)
                      .updateMinRating(v),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () =>
                  ref.read(searchFiltersProvider.notifier).resetFilters(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.check),
              label: const Text('Appliquer'),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _KoumassiMap extends ConsumerWidget {
  _KoumassiMap();

  static const LatLng _koumassiCenter = LatLng(5.309, -4.012);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(remoteProvidersFutureProvider);
    final theme = Theme.of(context);

    Set<Marker> markers = {};
    providers.when(
      data: (list) {
        markers = list
            .where((p) => p.latitude != 0 && p.longitude != 0)
            .map((p) => Marker(
                  markerId: MarkerId('p-${p.id}'),
                  position: LatLng(p.latitude, p.longitude),
                  infoWindow: InfoWindow(title: p.name),
                  onTap: () => context.go('/provider/${p.id}'),
                ))
            .toSet();
      },
      loading: () {},
      error: (_, __) {},
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _koumassiCenter,
                  zoom: 13.0,
                ),
                markers: markers,
                zoomControlsEnabled: false,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: FilledButton.icon(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.primary.withOpacity(0.95),
                  ),
                ),
                onPressed: () =>
                    FilterSheet.show(context, child: const _FiltersContent()),
                icon: const Icon(Icons.tune),
                label: const Text('Filtres'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
