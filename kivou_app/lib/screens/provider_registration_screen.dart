import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../services/upload_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle, MethodChannel;
import 'package:http/http.dart' as http;
import '../services/category_service.dart';

class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  const ProviderRegistrationScreen({super.key});
  @override
  ConsumerState<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends ConsumerState<ProviderRegistrationScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _price = TextEditingController(text: '100');
  final _description = TextEditingController();
  final _locationNote = TextEditingController();
  bool loading = false;
  File? _photo;
  // Sélection de catégories prédéfinies
  List<String> _allCategories = const [];
  bool _loadingCategories = true;
  List<String> _selectedCategories = [];
  // Position sur la carte
  double? _lat = 5.35; // Abidjan par défaut
  double? _lng = -4.02;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _price.dispose();
    _description.dispose();
    _locationNote.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!_loadingCategories) return;
    try {
      final api = ref.read(apiClientProvider);
      final svc = CategoryService(api);
      final names = await svc.listNames();
      if (mounted) {
        setState(() {
          _allCategories = names.isEmpty
              ? const [
                  'Plomberie',
                  'Électricité',
                  'Ménage',
                  'Jardinage',
                  'Peinture',
                  'Menuiserie',
                  'Climatisation',
                  'Serrurerie',
                  'Déménagement',
                  'Informatique',
                  'Coiffure'
                ]
              : names;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      return const Scaffold(
          body: Center(child: Text('Veuillez vous connecter.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir prestataire'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Accueil',
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _photo != null ? FileImage(_photo!) : null,
                  child: _photo == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Photo du prestataire'),
                )
              ],
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Nom du prestataire')),
            const SizedBox(height: 12),
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Téléphone')),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Prestations',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedCategories.isEmpty)
                  const Text('Sélectionnez une ou plusieurs catégories'),
                ..._selectedCategories.map((c) => Chip(
                      label: Text(c),
                      onDeleted: () {
                        setState(() => _selectedCategories.remove(c));
                      },
                    )),
                OutlinedButton.icon(
                  onPressed: _openCategoryPicker,
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('Choisir les catégories'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description du prestataire',
                hintText: 'Décrivez vos prestations, votre expérience, etc.',
              ),
            ),
            const SizedBox(height: 12),
            _PlacesAutocompleteField(
              controller: _locationNote,
              onPlaceSelected: (loc) {
                if (loc != null) {
                  setState(() {
                    _lat = loc.lat;
                    _lng = loc.lng;
                  });
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(_lat!, _lng!),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Position sur la carte',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_lat ?? 5.35, _lng ?? -4.02),
                    zoom: 12,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  myLocationButtonEnabled: false,
                  onTap: (pos) {
                    setState(() {
                      _lat = pos.latitude;
                      _lng = pos.longitude;
                    });
                  },
                  markers: {
                    if (_lat != null && _lng != null)
                      Marker(
                        markerId: const MarkerId('provider_pos'),
                        position: LatLng(_lat!, _lng!),
                        draggable: true,
                        onDragEnd: (p) => setState(() {
                          _lat = p.latitude;
                          _lng = p.longitude;
                        }),
                      )
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Lat: ${_lat?.toStringAsFixed(5) ?? '-'}'),
                ),
                Expanded(
                  child: Text('Lng: ${_lng?.toStringAsFixed(5) ?? '-'}'),
                ),
                IconButton(
                  tooltip: 'Centrer sur la position',
                  onPressed: () {
                    if (_mapController != null &&
                        _lat != null &&
                        _lng != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(_lat!, _lng!),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.my_location),
                )
              ],
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Tarif horaire'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Enregistrer'),
              ),
            )
          ]),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      final svc = ref.read(providerServiceProvider);
      String? uploadedUrl;
      if (_photo != null) {
        final token = ref.read(authStateProvider).token;
        uploadedUrl = await UploadService().uploadProviderPhoto(
          _photo!,
          bearerToken: token,
        );
      }
      final cats = _selectedCategories;
      if (cats.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Veuillez sélectionner au moins une catégorie')));
        }
        return;
      }
      // Construire la description finale (inclut la note de localisation si renseignée)
      final desc =
          (_description.text.trim().isEmpty ? '' : _description.text.trim()) +
              (_locationNote.text.trim().isEmpty
                  ? ''
                  : '\nAdresse: ${_locationNote.text.trim()}');
      await svc.registerProvider(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        categories: cats,
        pricePerHour: double.tryParse(_price.text) ?? 100,
        photoUrl: uploadedUrl,
        description: desc.isEmpty ? null : desc,
        latitude: _lat,
        longitude: _lng,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil prestataire créé.')));
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openCategoryPicker() async {
    final current = Set<String>.from(_selectedCategories);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final controller = TextEditingController();
        final all = List<String>.from(_allCategories);
        List<String> filtered = List<String>.from(all);
        return StatefulBuilder(builder: (ctx, setSt) {
          void applyFilter(String q) {
            setSt(() {
              final query = q.toLowerCase().trim();
              filtered = query.isEmpty
                  ? List<String>.from(all)
                  : all.where((c) => c.toLowerCase().contains(query)).toList();
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 64,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Rechercher une catégorie',
                      ),
                      onChanged: applyFilter,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        final checked = current.contains(c);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(c),
                          onChanged: (v) {
                            setSt(() {
                              if (v == true) {
                                current.add(c);
                              } else {
                                current.remove(c);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check),
                            onPressed: () =>
                                Navigator.pop(ctx, current.toList()),
                            label: const Text('Valider'),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
    if (result != null) {
      setState(() => _selectedCategories = result);
    }
  }
}

class _PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(_PlaceLoc?) onPlaceSelected;
  const _PlacesAutocompleteField({
    required this.controller,
    required this.onPlaceSelected,
  });
  @override
  State<_PlacesAutocompleteField> createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlaceLoc {
  final double lat;
  final double lng;
  final String description;
  _PlaceLoc(this.lat, this.lng, this.description);
}

class _PlacesAutocompleteFieldState extends State<_PlacesAutocompleteField> {
  String _apiKey = '';
  List<Map<String, String>> _predictions = [];
  bool _loading = false;
  http.Client _client = http.Client();
  static Map<String, dynamic>? _cachedEnv;
  static const MethodChannel _envChannel = MethodChannel('env');

  @override
  void initState() {
    super.initState();
    _apiKey =
        const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
    // Fallback: charge depuis un fichier d'assets env si disponible (assets/env.json)
    if (_apiKey.isEmpty) _loadEnvFromAssets();
    // Dernier fallback: demander à la plateforme (Android) la clé @string/google_maps_api_key
    if (_apiKey.isEmpty) _loadEnvFromPlatform();
  }

  Future<void> _loadEnvFromAssets() async {
    try {
      if (_cachedEnv == null) {
        final jsonStr = await rootBundle.loadString('assets/env.json');
        _cachedEnv = json.decode(jsonStr) as Map<String, dynamic>;
      }
      final k = (_cachedEnv?['GOOGLE_MAPS_API_KEY'] ?? '').toString();
      if (k.isNotEmpty && mounted) {
        setState(() => _apiKey = k);
      }
    } catch (_) {
      // ignore: asset load failures silently
    }
  }

  Future<void> _loadEnvFromPlatform() async {
    try {
      final k = await _envChannel.invokeMethod<String>('getGoogleMapsApiKey');
      if ((k ?? '').isNotEmpty && mounted) setState(() => _apiKey = k!);
    } catch (_) {
      // ignore platform failures
    }
  }

  Future<void> _onChanged(String value) async {
    if (value.trim().isEmpty || _apiKey.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = Uri.https(
          'maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': value,
        'key': _apiKey,
        'language': 'fr',
        'components': 'country:ci',
      });
      final resp = await _client.get(uri);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final preds = (data['predictions'] as List<dynamic>?) ?? [];
        setState(() {
          _predictions = preds
              .map((e) => {
                    'place_id': (e['place_id'] ?? '').toString(),
                    'description': (e['description'] ?? '').toString(),
                  })
              .where((m) => (m['place_id']!.isNotEmpty))
              .toList();
        });
      } else {
        setState(() => _predictions = []);
      }
    } catch (_) {
      setState(() => _predictions = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(Map<String, String> p) async {
    widget.controller.text = p['description'] ?? '';
    setState(() => _predictions = []);
    if (_apiKey.isEmpty) {
      widget.onPlaceSelected(null);
      return;
    }
    try {
      final placeId = p['place_id']!;
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
        'place_id': placeId,
        'key': _apiKey,
        'language': 'fr',
        'fields': 'geometry,formatted_address,name',
      });
      final resp = await _client.get(uri);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        final geo = (result?['geometry'] as Map<String, dynamic>?) ?? {};
        final loc = (geo['location'] as Map<String, dynamic>?) ?? {};
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          widget
              .onPlaceSelected(_PlaceLoc(lat, lng, p['description'] ?? 'Lieu'));
          return;
        }
      }
      widget.onPlaceSelected(null);
    } catch (_) {
      widget.onPlaceSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Localisation',
            hintText: 'Rechercher un lieu (Google Places)',
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : const Icon(Icons.place_outlined),
          ),
          onChanged: _onChanged,
        ),
        ..._predictions.map((p) => ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: const Icon(Icons.location_on_outlined, size: 18),
              title: Text(p['description'] ?? ''),
              onTap: () => _select(p),
            )),
      ],
    );
  }
}
