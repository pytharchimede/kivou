import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_providers.dart';
import '../services/ads_service.dart';
import '../services/provider_service.dart';
import '../services/upload_service.dart';
import 'gallery_viewer_screen.dart';

class AdComposeScreen extends ConsumerStatefulWidget {
  const AdComposeScreen({super.key});
  @override
  ConsumerState<AdComposeScreen> createState() => _AdComposeScreenState();
}

class _AdComposeScreenState extends ConsumerState<AdComposeScreen> {
  String kind = 'request';
  String authorType = 'client';
  String? providerId; // si authorType=provider
  String? imageUrl; // première image (legacy)
  final List<String> images = [];
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  bool submitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final img =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;
    final auth = ref.read(authStateProvider);
    final token = auth.token;
    final url =
        await UploadService().uploadAdImage(File(img.path), bearerToken: token);
    if (!mounted) return;
    setState(() {
      imageUrl ??= url; // garder la première pour compatibilité
      images.add(url);
    });
  }

  Future<void> _pickMultiple() async {
    final list = await _picker.pickMultiImage(imageQuality: 85);
    if (list.isEmpty) return;
    final auth = ref.read(authStateProvider);
    final token = auth.token;
    for (final x in list) {
      final url =
          await UploadService().uploadAdImage(File(x.path), bearerToken: token);
      if (!mounted) return;
      setState(() {
        imageUrl ??= url;
        images.add(url);
      });
    }
  }

  Future<void> _submit() async {
    if (titleCtrl.text.trim().isEmpty) return;
    setState(() => submitting = true);
    try {
      final svc = AdsService(ref.read(apiClientProvider));
      final amount = double.tryParse(amountCtrl.text.trim());
      final created = await svc.create(
        kind: kind,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        imageUrl: imageUrl,
        images: images,
        amount: amount,
        currency: 'XOF',
        authorType: authorType,
        providerId: authorType == 'provider' ? providerId : null,
      );
      // Remplir la table ad_images et persister l'ordre choisi par l'utilisateur
      try {
        final all = images.where((u) => u.isNotEmpty).toList();
        if (all.isNotEmpty) {
          await svc.addImages(adId: created.id, images: all);
          await svc.reorderImagesByUrls(adId: created.id, urls: all);
        }
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle annonce')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'request',
                    label: Text('Demande'),
                    icon: Icon(Icons.help_outline)),
                ButtonSegment(
                    value: 'offer',
                    label: Text('Offre'),
                    icon: Icon(Icons.sell_outlined)),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setState(() => kind = s.first),
            ),
            const SizedBox(height: 12),
            Text('Publier en tant que', style: theme.textTheme.titleSmall),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'client',
                    label: Text('Client'),
                    icon: Icon(Icons.person_outline)),
                ButtonSegment(
                    value: 'provider',
                    label: Text('Prestataire'),
                    icon: Icon(Icons.store_mall_directory_outlined)),
              ],
              selected: {authorType},
              onSelectionChanged: (s) => setState(() => authorType = s.first),
            ),
            const SizedBox(height: 12),
            if (authorType == 'provider')
              _ProviderPicker(
                onChanged: (id) => setState(() => providerId = id),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Montant (optionnel)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Ajouter une image'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickMultiple,
                  icon: const Icon(Icons.collections_outlined),
                  label: const Text('Ajouter plusieurs'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (images.isNotEmpty)
              SizedBox(
                height: 110,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  proxyDecorator: (child, index, animation) => Material(
                    elevation: 6,
                    child: child,
                  ),
                  itemCount: images.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = images.removeAt(oldIndex);
                      images.insert(newIndex, item);
                      imageUrl = images.isNotEmpty ? images.first : null;
                    });
                  },
                  itemBuilder: (ctx, i) {
                    final url = images[i];
                    return Padding(
                      key: ValueKey(url),
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GalleryViewerScreen(
                                  images: images,
                                  initialIndex: i,
                                  title: 'Aperçu',
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 120,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
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
                                onTap: () {
                                  setState(() {
                                    final removed = images.removeAt(i);
                                    if (imageUrl == removed) {
                                      imageUrl = images.isNotEmpty
                                          ? images.first
                                          : null;
                                    }
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close,
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : _submit,
                icon: const Icon(Icons.send_rounded),
                label: Text(submitting ? 'Publication…' : 'Publier'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ProviderPicker extends ConsumerStatefulWidget {
  final void Function(String? id) onChanged;
  const _ProviderPicker({required this.onChanged});
  @override
  ConsumerState<_ProviderPicker> createState() => _ProviderPickerState();
}

class _ProviderPickerState extends ConsumerState<_ProviderPicker> {
  String? selected;
  late Future<List<dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = ProviderService(ref.read(apiClientProvider)).listMine();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (ctx, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final list = snap.data!;
        return DropdownButtonFormField<String>(
          value: selected,
          items: list.map((e) {
            final id = (e['id'] ?? '').toString();
            final name = (e['name'] ?? '').toString();
            return DropdownMenuItem(value: id, child: Text(name));
          }).toList(),
          onChanged: (v) {
            setState(() => selected = v);
            widget.onChanged(v);
          },
          decoration:
              const InputDecoration(labelText: 'Choisir le prestataire'),
        );
      },
    );
  }
}
