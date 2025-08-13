import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ads_service.dart';
import '../providers/app_providers.dart';
import '../services/mappers.dart';

class AdEditImagesScreen extends ConsumerStatefulWidget {
  final int adId;
  const AdEditImagesScreen({super.key, required this.adId});

  @override
  ConsumerState<AdEditImagesScreen> createState() => _AdEditImagesScreenState();
}

class _AdEditImagesScreenState extends ConsumerState<AdEditImagesScreen> {
  bool _loading = true;
  bool _saving = false;
  late AdsService _svc;
  List<String> _images = [];
  // Ad? _ad; // non utilisé

  @override
  void initState() {
    super.initState();
    _svc = AdsService(ref.read(apiClientProvider));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ad = await _svc.detail(widget.adId);
      setState(() {
        // _ad = ad;
        // Normaliser pour affichage côté client
        _images = ad.images
            .map((e) => normalizeImageUrl(e))
            .where((e) => e.isNotEmpty)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final prev = List<String>.from(_images);
    setState(() {
      final it = _images.removeAt(oldIndex);
      _images.insert(newIndex, it);
    });
    setState(() => _saving = true);
    try {
      await _svc.reorderImagesByUrls(adId: widget.adId, urls: _images);
    } catch (e) {
      setState(() => _images = prev);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Échec du tri: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAt(int index) async {
    final url = _images[index];
    setState(() => _saving = true);
    try {
      await _svc.deleteImage(adId: widget.adId, url: url);
      setState(() => _images.removeAt(index));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Suppression échouée: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditer les images'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_images.isEmpty
              ? const Center(child: Text('Aucune image'))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 120,
                    child: ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      onReorder: _reorder,
                      proxyDecorator: (child, index, animation) =>
                          Material(elevation: 6, child: child),
                      itemBuilder: (ctx, i) {
                        final url = _images[i];
                        return Padding(
                          key: ValueKey(url),
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  normalizeImageUrl(url),
                                  width: 140,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _deleteAt(i),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.delete_outline,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )),
    );
  }
}
