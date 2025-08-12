class Announcement {
  final int id;
  final String type; // 'request' | 'offer'
  final String authorRole; // 'client' | 'provider'
  final String? providerId;
  final String title;
  final String description;
  final double? price;
  final List<String> images;
  final DateTime createdAt;
  final int publisherUserId;
  final String publisherName;
  final String? publisherAvatarUrl;

  Announcement({
    required this.id,
    required this.type,
    required this.authorRole,
    required this.providerId,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.createdAt,
    required this.publisherUserId,
    required this.publisherName,
    required this.publisherAvatarUrl,
  });

  factory Announcement.fromApi(Map<String, dynamic> j) {
    return Announcement(
      id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
      type: j['type']?.toString() ?? 'request',
      authorRole: j['author_role']?.toString() ?? 'client',
      providerId: j['provider_id']?.toString(),
      title: j['title']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      price: j['price'] == null ? null : double.tryParse(j['price'].toString()),
      images: (j['images'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      publisherUserId:
          int.tryParse(j['publisher_user_id']?.toString() ?? '') ?? 0,
      publisherName: j['publisher_name']?.toString() ?? 'Utilisateur',
      publisherAvatarUrl: j['publisher_avatar_url']?.toString(),
    );
  }
}
