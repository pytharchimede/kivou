import '../models/service_provider.dart';
import '../models/booking.dart';
import '../models/review.dart';

/// Données mock pour tester l'application KIVOU
class MockData {
  // ---------- Paramètres globaux ----------
  static const double userLatitude = 5.3364; // Centre Abidjan
  static const double userLongitude = -3.9569;

  static const List<String> serviceCategories = [
    'Tous',
    'Ménage ponctuel',
    'Jardinage',
    'Électricité',
    'Plomberie',
    'Menuiserie',
    'Nettoyage',
    'Dépannage',
    'Aménagement paysager',
    'Sanitaire',
    'Ébénisterie',
  ];

  // ---------- Génération déterministe ----------
  static int _seed = 42;
  static int _next() {
    // LCG simple pour pseudo-aléatoire déterministe
    _seed = (1664525 * _seed + 1013904223) & 0x7fffffff;
    return _seed;
  }

  static double _rand() => _next() / 0x7fffffff; // 0..1

  static double _randIn(double min, double max) => min + (max - min) * _rand();

  static String _pick(List<String> list) =>
      list[(_rand() * list.length).floor().clamp(0, list.length - 1)];

  static List<String> _shufflePick(
      List<String> list, int minCount, int maxCount) {
    final copy = List<String>.from(list);
    // mélange simple
    for (int i = copy.length - 1; i > 0; i--) {
      final j = (_rand() * (i + 1)).floor();
      final tmp = copy[i];
      copy[i] = copy[j];
      copy[j] = tmp;
    }
    final count = (minCount + (_rand() * (maxCount - minCount + 1)))
        .floor()
        .clamp(1, copy.length);
    return copy.sublist(0, count);
  }

  // ---------- Providers (60+) ----------
  static final List<ServiceProvider> providers = _generateProviders(60);

  static List<ServiceProvider> _generateProviders(int count) {
    final baseNames = [
      'Awa',
      'Kouma',
      'Oumar',
      'Fatou',
      'Ibrahim',
      'Mariam',
      'Koffi',
      'Adjoba',
      'Yao',
      'Nana',
      'Zeynab',
      'Ismaël',
      'Salif',
      'Aïcha',
      'Souleymane',
      'Aminata',
      'Paul',
      'Nadine',
      'Michel',
      'Grace'
    ];
    final specialties = {
      'Ménage ponctuel': ['Nettoyage', 'Désinfection'],
      'Jardinage': ['Aménagement paysager', 'Entretien'],
      'Électricité': ['Dépannage', 'Installation'],
      'Plomberie': ['Sanitaire', 'Dépannage'],
      'Menuiserie': ['Ébénisterie', 'Montage']
    };
    final photos = [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
      'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
      'https://images.unsplash.com/photo-1581091870622-3a3f34f6b1d5?w=800',
      'https://images.unsplash.com/photo-1595273670150-bd0c3c392e46?w=800',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800',
      'https://images.unsplash.com/photo-1496483353456-90997957cf99?w=800',
      'https://images.unsplash.com/photo-1560184897-6b99e6d1c3a8?w=800',
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800',
    ];

    final list = <ServiceProvider>[];
    for (int i = 1; i <= count; i++) {
      final baseName = _pick(baseNames);
      final category = _pick(specialties.keys.toList());
      final otherCats = specialties[category]!;
      final cats = [category, ..._shufflePick(otherCats, 1, otherCats.length)];
      final rating = (3.5 + _randIn(0, 1.5)); // 3.5 .. 5.0
      final reviews = (30 + (_rand() * 400)).floor();
      final price = [8.0, 9.0, 10.0, 12.0, 15.0][(_rand() * 5).floor()];
      // Rayon ~8km autour du centre
      final lat = userLatitude + _randIn(-0.06, 0.06);
      final lng = userLongitude + _randIn(-0.06, 0.06);
      final phone =
          '+225 07 ${(_randIn(10, 99)).floor()} ${(_randIn(10, 99)).floor()} ${(_randIn(10, 99)).floor()} ${(_randIn(10, 99)).floor()}';
      final photo = _pick(photos);
      final gallery = _shufflePick(photos, 2, 4);
      final days = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday'
      ];
      final startHour = [7, 8, 9][(_rand() * 3).floor()];
      final endHour = startHour + [8, 9, 10][(_rand() * 3).floor()];
      final isAvailable = _rand() > 0.15; // ~85% dispo
      final createdAt =
          DateTime.now().subtract(Duration(days: (_rand() * 240).floor()));

      list.add(
        ServiceProvider(
          id: 'p$i',
          name: '$baseName ${category.split(' ').first}',
          email: '${baseName.toLowerCase()}.$i@kivou.ci',
          phone: phone,
          photoUrl: photo,
          description:
              'Prestataire $category avec expérience locale. Interventions rapides et soignées. (#$i)',
          categories: cats,
          rating: double.parse(rating.toStringAsFixed(1)),
          reviewsCount: reviews,
          pricePerHour: price,
          latitude: lat,
          longitude: lng,
          gallery: gallery,
          availableDays: days,
          workingHours: TimeSlot(
              start: '${startHour.toString().padLeft(2, '0')}:00',
              end: '${endHour.toString().padLeft(2, '0')}:00'),
          isAvailable: isAvailable,
          createdAt: createdAt,
        ),
      );
    }
    return list;
  }

  // ---------- Bookings (24) ----------
  static List<Booking> generateMockBookings() {
    final list = <Booking>[];
    final statuses = [
      BookingStatus.pending,
      BookingStatus.confirmed,
      BookingStatus.inProgress,
      BookingStatus.completed,
      BookingStatus.cancelled,
    ];
    for (int i = 1; i <= 24; i++) {
      final prov = providers[(_rand() * providers.length).floor()];
      final status = statuses[(_rand() * statuses.length).floor()];
      final daysOffset = (_randIn(-20, 20)).floor();
      final sched = DateTime.now()
          .add(Duration(days: daysOffset, hours: (_randIn(8, 18)).floor()));
      final duration = [1.0, 1.5, 2.0, 3.0, 4.0][(_rand() * 5).floor()];
      final total = prov.pricePerHour * duration;
      list.add(
        Booking(
          id: 'b$i',
          userId: 'user1',
          providerId: prov.id,
          serviceCategory: prov.categories.first,
          serviceDescription: prov.categories.join(', '),
          scheduledAt: sched,
          duration: duration,
          totalPrice: total,
          status: status,
          createdAt: sched.subtract(const Duration(days: 1)),
          completedAt: status == BookingStatus.completed ? sched : null,
          payment: status == BookingStatus.completed
              ? PaymentInfo(
                  method: 'card',
                  transactionId: 'tx_$i',
                  paidAt: sched,
                  amount: total)
              : null,
        ),
      );
    }
    return list;
  }

  // ---------- Reviews (50) ----------
  static List<Review> generateMockReviews() {
    final list = <Review>[];
    for (int i = 1; i <= 50; i++) {
      final prov = providers[(_rand() * providers.length).floor()];
      final rating = (3.0 + _randIn(0, 2.0));
      list.add(
        Review(
          id: 'r$i',
          bookingId: 'b${(i % 24) + 1}',
          userId: 'user${(i % 5) + 1}',
          providerId: prov.id,
          rating: double.parse(rating.toStringAsFixed(1)),
          comment: _rand() > 0.3
              ? 'Prestation ${prov.categories.first} bien réalisée (#$i).'
              : null,
          photos: null,
          createdAt:
              DateTime.now().subtract(Duration(days: (_rand() * 60).floor())),
          providerResponse: _rand() > 0.7
              ? ReviewResponse(
                  response: 'Merci pour votre confiance !',
                  respondedAt: DateTime.now()
                      .subtract(Duration(days: (_rand() * 30).floor())),
                )
              : null,
        ),
      );
    }
    return list;
  }

  // ---------- Helpers filtres ----------
  static ServiceProvider? getProviderById(String id) {
    try {
      return providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<ServiceProvider> filterByCategory(String category) {
    if (category == 'Tous') return providers;
    return providers.where((p) => p.categories.contains(category)).toList();
  }

  static List<ServiceProvider> filterByDistance(double maxDistanceKm) {
    return providers.where((p) {
      final d = p.distanceFrom(userLatitude, userLongitude);
      return d <= maxDistanceKm;
    }).toList();
  }

  static List<ServiceProvider> filterByRating(double minRating) {
    return providers.where((p) => p.rating >= minRating).toList();
  }
}
