import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../models/service_provider.dart';
import '../services/announcement_service.dart';
import '../services/announcement_upload_service.dart';
import '../services/mappers.dart';

class AnnouncementCreateScreen extends ConsumerStatefulWidget {
  const AnnouncementCreateScreen({super.key});
  @override
  ConsumerState<AnnouncementCreateScreen> createState() =>
      _AnnouncementCreateScreenState();
}

class _AnnouncementCreateScreenState
    extends ConsumerState<AnnouncementCreateScreen> {
  String _type = 'request';
  String _role = 'client';
  ServiceProvider? _selectedProvider;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];
  bool _submitting = false;

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 85);
    if (imgs.isEmpty) return;
    setState(() {
      _images.addAll(imgs.map((e) => File(e.path)));
    });
  }

  Future<void> _chooseProvider() async {
    // Charger prestataires et filtrer ceux dont owner_user_id == current user id
    final auth = ref.read(authStateProvider);
    final list = await ref.read(providerServiceProvider).list();
    final providers =
        list.map((e) => providerFromApi(e as Map<String, dynamic>)).toList();
    final mine = providers
        .where((p) => p.ownerUserId == (auth.user?['id'] as int?))
        .toList();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<ServiceProvider>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (c, i) {
            final p = mine[i];
            return ListTile(
              leading: CircleAvatar(
                  backgroundImage:
                      p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
                  child:
                      p.photoUrl.isEmpty ? const Icon(Icons.storefront) : null),
              title: Text(p.name),
              subtitle: Text(p.categories.join(', ')),
              onTap: () => Navigator.pop(c, p),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: mine.length,
        ),
      ),
    );
    if (chosen != null) setState(() => _selectedProvider = chosen);
  }

  Future<void> _submit() async {
    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated) {
      if (mounted) context.go('/auth');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Titre requis')));
      return;
    }
    if (_role == 'provider' && _selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez un prestataire')));
      return;
    }
    setState(() => _submitting = true);
    try {
      // Upload images d'abord (si offre)
      List<String> urls = [];
      if (_images.isNotEmpty) {
        final up = AnnouncementUploadService();
        for (final f in _images) {
          urls.add(await up.upload(f));
        }
      }
      final id = await ref.read(announcementServiceProvider).create(
            type: _type,
            authorRole: _role,
            providerId: _selectedProvider?.id,
            title: _titleCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            price: _type == 'offer' && _priceCtrl.text.trim().isNotEmpty
                ? double.tryParse(_priceCtrl.text.trim())
                : null,
            images: urls,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Annonce publiée')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
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
            Text('Publier en tant que', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                  label: const Text('Client'),
                  selected: _role == 'client',
                  onSelected: (_) => setState(() {
                        _role = 'client';
                      })),
              ChoiceChip(
                  label: const Text('Prestataire'),
                  selected: _role == 'provider',
                  onSelected: (_) => setState(() {
                        _role = 'provider';
                      })),
            ]),
            if (_role == 'provider') ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _chooseProvider,
                icon: const Icon(Icons.storefront_rounded),
                label:
                    Text(_selectedProvider?.name ?? 'Choisir un prestataire'),
              ),
            ],
            const SizedBox(height: 16),
            Text('Type d\'annonce', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                  label: const Text('Demande'),
                  selected: _type == 'request',
                  onSelected: (_) => setState(() {
                        _type = 'request';
                      })),
              ChoiceChip(
                  label: const Text('Offre'),
                  selected: _type == 'offer',
                  onSelected: (_) => setState(() {
                        _type = 'offer';
                      })),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 3,
              maxLines: 6,
            ),
            if (_type == 'offer') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in _images)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(f,
                          width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: -8,
                      top: -8,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          _images.remove(f);
                        }),
                      ),
                    )
                  ],
                ),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo_rounded),
                label: const Text('Images'),
              )
            ]),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(_submitting ? 'Publication…' : 'Publier'),
            ),
          ],
        ),
      ),
    );
  }
}
