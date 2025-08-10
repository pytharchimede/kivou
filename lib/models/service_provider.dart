/// Modèle représentant un prestataire de service
class ServiceProvider {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String description;
  final List<String> categories;
  final double rating;
  final int reviewsCount;
  final double pricePerHour;
  final double latitude;
  final double longitude;
  final List<String> gallery;
  final List<String> availableDays; // ['monday', 'tuesday', ...]
  final TimeSlot workingHours;
  final bool isAvailable;
  final DateTime createdAt;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.description,
    required this.categories,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerHour,
    required this.latitude,
    required this.longitude,
    required this.gallery,
    required this.availableDays,
    required this.workingHours,
    required this.isAvailable,
    required this.createdAt,
  });

  /// Distance depuis un point donné (en kilomètres)
  double distanceFrom(double lat, double lng) {
    // Calcul simplifié de distance (pour production, utiliser geolocator)
    const double earthRadius = 6371; // Rayon de la Terre en km
    double dLat = _toRadians(latitude - lat);
    double dLng = _toRadians(longitude - lng);

    double a =
        (dLat / 2) * (dLat / 2) + (dLng / 2) * (dLng / 2) * (lat * (latitude));
    double c = 2 * (a);

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.14159 / 180);
  }

  ServiceProvider copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? description,
    List<String>? categories,
    double? rating,
    int? reviewsCount,
    double? pricePerHour,
    double? latitude,
    double? longitude,
    List<String>? gallery,
    List<String>? availableDays,
    TimeSlot? workingHours,
    bool? isAvailable,
  }) {
    return ServiceProvider(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gallery: gallery ?? this.gallery,
      availableDays: availableDays ?? this.availableDays,
      workingHours: workingHours ?? this.workingHours,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
    );
  }
}

/// Créneau horaire
class TimeSlot {
  final String start; // Format "HH:mm"
  final String end; // Format "HH:mm"

  TimeSlot({
    required this.start,
    required this.end,
  });

  @override
  String toString() => '$start - $end';
}
