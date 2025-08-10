/// Modèle représentant une réservation/commande
class Booking {
  final String id;
  final String userId;
  final String providerId;
  final String serviceCategory;
  final String serviceDescription;
  final DateTime scheduledAt;
  final double duration; // en heures
  final double totalPrice;
  final BookingStatus status;
  final String? customerNotes;
  final String? providerNotes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final PaymentInfo? payment;

  Booking({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.serviceCategory,
    required this.serviceDescription,
    required this.scheduledAt,
    required this.duration,
    required this.totalPrice,
    required this.status,
    this.customerNotes,
    this.providerNotes,
    required this.createdAt,
    this.completedAt,
    this.payment,
  });

  Booking copyWith({
    BookingStatus? status,
    String? customerNotes,
    String? providerNotes,
    DateTime? completedAt,
    PaymentInfo? payment,
  }) {
    return Booking(
      id: id,
      userId: userId,
      providerId: providerId,
      serviceCategory: serviceCategory,
      serviceDescription: serviceDescription,
      scheduledAt: scheduledAt,
      duration: duration,
      totalPrice: totalPrice,
      status: status ?? this.status,
      customerNotes: customerNotes ?? this.customerNotes,
      providerNotes: providerNotes ?? this.providerNotes,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      payment: payment ?? this.payment,
    );
  }

  /// Durée formatée
  String get formattedDuration {
    if (duration == duration.floor()) {
      return '${duration.toInt()}h';
    } else {
      int hours = duration.floor();
      int minutes = ((duration - hours) * 60).round();
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
  }

  /// Prix formaté
  String get formattedPrice => '${totalPrice.toStringAsFixed(2)} €';
}

/// Statut d'une réservation
enum BookingStatus {
  pending('En attente'),
  confirmed('Confirmée'),
  inProgress('En cours'),
  completed('Terminée'),
  cancelled('Annulée'),
  refunded('Remboursée');

  const BookingStatus(this.label);
  final String label;
}

/// Informations de paiement
class PaymentInfo {
  final String method; // 'card', 'paypal', 'cash'
  final String? transactionId;
  final DateTime paidAt;
  final double amount;

  PaymentInfo({
    required this.method,
    this.transactionId,
    required this.paidAt,
    required this.amount,
  });
}
