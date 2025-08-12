import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import '../providers/app_providers.dart';
import '../widgets/provider_card.dart';
import '../models/chat.dart';
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
          _BellButton(),
          _ChatsWithBadgeButton(),
          IconButton(
              onPressed: () => context.go('/orders'),
              icon: const Icon(Icons.receipt_long)),
          const _ProfileWithBadgeButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalider et recharger
          ref.invalidate(remoteProvidersFutureProvider);
          // Rafraîchir aussi le compteur des commandes en attente
          await ref.read(ownerPendingCountProvider.notifier).refresh();
          try {
            await ref.read(remoteProvidersFutureProvider.future);
          } catch (_) {}
        },
        child: CustomScrollView(
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
          onPressed: () => context.go('/profile'),
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
              context.go('/auth');
            } else {
              context.push('/chats');
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

class _KoumassiMap extends ConsumerStatefulWidget {
  _KoumassiMap();

  static const LatLng _koumassiCenter = LatLng(5.309, -4.012);

  @override
  ConsumerState<_KoumassiMap> createState() => _KoumassiMapState();
}

class _KoumassiMapState extends ConsumerState<_KoumassiMap> {
  GoogleMapController? _controller;
  LatLng? _userLatLng;
  // bool _locLoading = false;
  double _radiusKm = 10;
  final Map<int, BitmapDescriptor> _iconCache = {};
  final Set<int> _iconLoading = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // setState(() => _locLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        // fallback Koumassi
        _userLatLng = _KoumassiMap._koumassiCenter;
      } else {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        _userLatLng = LatLng(pos.latitude, pos.longitude);
      }
      if (mounted && _controller != null && _userLatLng != null) {
        await _controller!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: _userLatLng!, zoom: 13.5)));
      }
    } catch (_) {
      _userLatLng = _KoumassiMap._koumassiCenter;
    } finally {}
  }

  bool _withinRadius(double lat, double lng) {
    if (_userLatLng == null) return true;
    final d =
        _haversine(_userLatLng!.latitude, _userLatLng!.longitude, lat, lng);
    return d <= _radiusKm;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * 3.1415926535 / 180.0;

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(remoteProvidersFutureProvider);
    final theme = Theme.of(context);

    Set<Marker> markers = {};
    providers.when(
      data: (list) {
        markers = list
            .where((p) => p.latitude != 0 && p.longitude != 0)
            .where((p) => _withinRadius(p.latitude, p.longitude))
            .map((p) {
          final pid = int.tryParse(p.id) ?? p.id.hashCode;
          final icon = _iconCache[pid];
          if (icon == null && !_iconLoading.contains(pid)) {
            _iconLoading.add(pid);
            _buildMarkerIcon(p.photoUrl, p.name).then((bmp) {
              _iconCache[pid] = bmp;
              _iconLoading.remove(pid);
              if (mounted) setState(() {});
            }).catchError((_) {
              _iconLoading.remove(pid);
            });
          }
          return Marker(
            markerId: MarkerId('p-${p.id}'),
            position: LatLng(p.latitude, p.longitude),
            infoWindow: InfoWindow(title: p.name),
            icon: icon ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure),
            onTap: () => context.go('/provider/${p.id}'),
          );
        }).toSet();
      },
      loading: () {},
      error: (_, __) {},
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _KoumassiMap._koumassiCenter,
                  zoom: 13.0,
                ),
                onMapCreated: (c) => _controller = c,
                markers: markers,
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Column(
                children: [
                  FilledButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.colorScheme.primary.withValues(alpha: 0.95),
                      ),
                    ),
                    onPressed: () => FilterSheet.show(context,
                        child: const _FiltersContent()),
                    icon: const Icon(Icons.tune),
                    label: const Text('Filtres'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _initLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Moi'),
                  ),
                ],
              ),
            ),
            if (_userLatLng != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radar, size: 16),
                      const SizedBox(width: 6),
                      Text('Rayon ${_radiusKm.toStringAsFixed(0)} km'),
                      Slider(
                        value: _radiusKm,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '${_radiusKm.toStringAsFixed(0)} km',
                        onChanged: (v) => setState(() => _radiusKm = v),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<BitmapDescriptor> _buildMarkerIcon(
      String photoUrl, String name) async {
    const int width = 68; // px (encore réduit)
    const int height = 86; // px total (encore réduit)
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();

    // Transparent bg
    paint.color = const ui.Color(0x00000000);
    canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);

    // Zone de l'image (réduite)
    const double circleSize = 44;
    final double cx = width / 2;
    final double cy = circleSize / 2 + 4;
    final circleRect = ui.Rect.fromCenter(
        center: ui.Offset(cx, cy), width: circleSize, height: circleSize);

    // Ombre légère
    paint.color = const ui.Color(0x22000000);
    canvas.drawCircle(ui.Offset(cx, cy + 1.5), circleSize / 2, paint);

    // Load image
    ui.Image? img;
    try {
      if (photoUrl.isNotEmpty) {
        final resp = await http.get(Uri.parse(photoUrl));
        if (resp.statusCode == 200) {
          final codec = await ui.instantiateImageCodec(resp.bodyBytes,
              targetWidth: circleSize.toInt(),
              targetHeight: circleSize.toInt());
          final fi = await codec.getNextFrame();
          img = fi.image;
        }
      }
    } catch (_) {}

    // Clip circle and draw
    final clipPath = ui.Path()..addOval(circleRect);
    canvas.save();
    canvas.clipPath(clipPath);
    if (img != null) {
      final src =
          ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = circleRect;
      canvas.drawImageRect(img, src, dst, ui.Paint());
    } else {
      // Placeholder color
      paint.color = const ui.Color(0xFFBBDEFB);
      canvas.drawRect(circleRect, paint);
      final initials = _initials(name);
      final tp =
          _textPainter(initials, 40, const ui.Color(0xFF0D47A1), bold: true);
      tp.layout(maxWidth: circleRect.width);
      tp.paint(canvas, ui.Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
    canvas.restore();

    // Bordure blanche
    paint
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const ui.Color(0xFFFFFFFF);
    canvas.drawOval(circleRect, paint);

    // Label background below
    final label = name.trim().isEmpty ? 'Prestataire' : name.trim();
    const double pad = 4;
    final tpName = _textPainter(label, 10, const ui.Color(0xFF0D47A1),
        bold: true, maxLines: 1, ellipsis: '…');
    tpName.layout(maxWidth: width - 8);
    final labelW = tpName.width + pad * 2;
    final labelH = tpName.height + pad;
    final rr = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
          center: ui.Offset(cx, circleRect.bottom + 8),
          width: labelW,
          height: labelH),
      const ui.Radius.circular(8),
    );
    paint
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.95);
    canvas.drawRRect(rr, paint);
    tpName.paint(
        canvas, ui.Offset(rr.left + pad, rr.center.dy - tpName.height / 2));

    final picture = recorder.endRecording();
    final imgOut = await picture.toImage(width, height);
    final byteData = await imgOut.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  static TextPainter _textPainter(String text, double size, ui.Color color,
      {bool bold = false, int? maxLines, String? ellipsis}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: ellipsis,
    );
    return tp;
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first
          .substring(0, math.min(2, parts.first.length))
          .toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
