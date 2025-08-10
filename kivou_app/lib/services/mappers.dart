import 'package:kivou_app/models/service_provider.dart';

// Normalise une URL d'image: gère http->https, chemins relatifs avec ou sans '/'
String normalizeImageUrl(String? u) {
  if (u == null || u.isEmpty) return '';
  final s = u.trim();
  if (s.startsWith('http://fidest.ci')) {
    return s.replaceFirst('http://', 'https://');
  }
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (s.startsWith('/')) return 'https://fidest.ci$s';
  // Cas: 'kivou/backend/uploads/...' ou 'uploads/...'
  if (s.startsWith('kivou/')) return 'https://fidest.ci/$s';
  if (s.startsWith('backend/uploads') || s.startsWith('uploads/')) {
    return 'https://fidest.ci/kivou/$s'
        .replaceFirst('kivou/backend', 'kivou/backend');
  }
  return s;
}

ServiceProvider providerFromApi(Map<String, dynamic> j) {
  List<String> _split(String? s) => s == null || s.isEmpty
      ? []
      : s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  final photo = normalizeImageUrl(j['photo_url']?.toString());
  final rawGallery = (j['gallery'] is List)
      ? List<String>.from(j['gallery'])
      : _split(j['gallery']?.toString());
  final gallery = rawGallery.map(normalizeImageUrl).toList();

  return ServiceProvider(
    id: (j['id'] ?? '').toString(),
    ownerUserId: (j['owner_user_id'] == null || j['owner_user_id'] == '')
        ? null
        : (j['owner_user_id'] is num)
            ? (j['owner_user_id'] as num).toInt()
            : int.tryParse(j['owner_user_id'].toString()),
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    phone: j['phone'] ?? '',
    photoUrl: photo,
    description: j['description'] ?? '',
    categories: (j['categories'] is List)
        ? List<String>.from(j['categories'])
        : _split(j['categories']?.toString()),
    rating: (j['rating'] is num)
        ? (j['rating'] as num).toDouble()
        : double.tryParse(j['rating']?.toString() ?? '0') ?? 0,
    reviewsCount: (j['reviews_count'] is num)
        ? (j['reviews_count'] as num).toInt()
        : int.tryParse(j['reviews_count']?.toString() ?? '0') ?? 0,
    pricePerHour: (j['price_per_hour'] is num)
        ? (j['price_per_hour'] as num).toDouble()
        : double.tryParse(j['price_per_hour']?.toString() ?? '0') ?? 0,
    latitude: (j['latitude'] is num)
        ? (j['latitude'] as num).toDouble()
        : double.tryParse(j['latitude']?.toString() ?? '0') ?? 0,
    longitude: (j['longitude'] is num)
        ? (j['longitude'] as num).toDouble()
        : double.tryParse(j['longitude']?.toString() ?? '0') ?? 0,
    gallery: gallery,
    availableDays: (j['available_days'] is List)
        ? List<String>.from(j['available_days'])
        : _split(j['available_days']?.toString()),
    workingHours: TimeSlot(
      start: j['working_start']?.toString() ?? '08:00',
      end: j['working_end']?.toString() ?? '17:00',
    ),
    isAvailable: (j['is_available']?.toString() ?? '1') == '1',
    createdAt:
        DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
  );
}
