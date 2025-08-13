class Ad {
  final int id;
  final int authorUserId;
  final String authorType; // client | provider
  final String? providerId;
  final String kind; // request | offer
  final String title;
  final String description;
  final String imageUrl; // rétrocompatibilité (première image)
  final List<String> images; // multi-images
  final double? amount;
  final String currency;
  final String category;
  final double? lat;
  final double? lng;
  final String status; // active | closed | archived
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorName;
  final String authorAvatarUrl;
  final String providerName;
  final String providerPhotoUrl;

  const Ad({
    required this.id,
    required this.authorUserId,
    required this.authorType,
    required this.providerId,
    required this.kind,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.images,
    required this.amount,
    required this.currency,
    required this.category,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.providerName,
    required this.providerPhotoUrl,
  });

  factory Ad.fromApi(Map<String, dynamic> j) {
    // multi-images: accepter images sous plusieurs formes
    List<String> parsedImages = const [];
    final rawImages = j['images'];
    if (rawImages is List) {
      parsedImages = rawImages
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      final csv = (j['image_urls'] ?? j['images_csv'] ?? '').toString();
      if (csv.isNotEmpty) {
        parsedImages = csv
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    final single = j['image_url']?.toString() ?? '';
    if (parsedImages.isEmpty && single.isNotEmpty) {
      parsedImages = [single];
    }
    return Ad(
      id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      authorUserId: int.tryParse(j['author_user_id']?.toString() ?? '0') ?? 0,
      authorType: j['author_type']?.toString() ?? 'client',
      providerId: j['provider_id']?.toString(),
      kind: j['kind']?.toString() ?? 'offer',
      title: j['title']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      imageUrl: (parsedImages.isNotEmpty ? parsedImages.first : single),
      images: parsedImages,
      amount: j['amount'] == null
          ? null
          : double.tryParse(j['amount']?.toString() ?? ''),
      currency: j['currency']?.toString() ?? 'XOF',
      category: j['category']?.toString() ?? '',
      lat:
          j['lat'] == null ? null : double.tryParse(j['lat']?.toString() ?? ''),
      lng:
          j['lng'] == null ? null : double.tryParse(j['lng']?.toString() ?? ''),
      status: j['status']?.toString() ?? 'active',
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(j['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      authorName: j['author_name']?.toString() ?? '',
      authorAvatarUrl: j['author_avatar_url']?.toString() ?? '',
      providerName: j['provider_name']?.toString() ?? '',
      providerPhotoUrl: j['provider_photo_url']?.toString() ?? '',
    );
  }
}
