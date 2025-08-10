/// Modèle représentant un avis/évaluation
class Review {
  final String id;
  final String bookingId;
  final String userId;
  final String providerId;
  final double rating; // 1-5 étoiles
  final String? comment;
  final List<String>? photos;
  final DateTime createdAt;
  final ReviewResponse? providerResponse;

  Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.providerId,
    required this.rating,
    this.comment,
    this.photos,
    required this.createdAt,
    this.providerResponse,
  });

  Review copyWith({
    double? rating,
    String? comment,
    List<String>? photos,
    ReviewResponse? providerResponse,
  }) {
    return Review(
      id: id,
      bookingId: bookingId,
      userId: userId,
      providerId: providerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      createdAt: createdAt,
      providerResponse: providerResponse ?? this.providerResponse,
    );
  }

  /// Rating formaté avec étoiles
  String get formattedRating => '$rating ★';
}

/// Réponse du prestataire à un avis
class ReviewResponse {
  final String response;
  final DateTime respondedAt;

  ReviewResponse({
    required this.response,
    required this.respondedAt,
  });
}

/// Modèle représentant un utilisateur
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.address,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return User(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt,
    );
  }
}
