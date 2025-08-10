import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_provider.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../services/provider_service.dart';
import '../services/mappers.dart';
import '../services/session_storage.dart';
import '../services/auth_service.dart';

/// Provider pour la liste des prestataires (local cache optionnel)
final providersProvider = Provider<List<ServiceProvider>>((ref) => const []);

/// Client et services API
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final sessionStorageProvider =
    Provider<SessionStorage>((ref) => SessionStorage());
final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.read(apiClientProvider)));

class AuthState {
  final Map<String, dynamic>? user;
  final String? token;
  bool get isAuthenticated => user != null && token != null;
  const AuthState({this.user, this.token});
  AuthState copyWith({Map<String, dynamic>? user, String? token}) =>
      AuthState(user: user ?? this.user, token: token ?? this.token);
}

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  AuthController(this.ref) : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final storage = ref.read(sessionStorageProvider);
    final token = await storage.token;
    final user = await storage.user;
    if (token != null && user != null) {
      ref.read(apiClientProvider).setBearerToken(token);
      state = AuthState(user: user, token: token);
    }
  }

  Future<void> login(String email, String password) async {
    final svc = ref.read(authServiceProvider);
    final data = await svc.login(email, password);
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await ref.read(sessionStorageProvider).saveSession(token, user);
    ref.read(apiClientProvider).setBearerToken(token);
    state = AuthState(user: user, token: token);
  }

  Future<void> register(String email, String password, String name,
      {String? phone}) async {
    final svc = ref.read(authServiceProvider);
    final data = await svc.register(email, password, name, phone: phone);
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await ref.read(sessionStorageProvider).saveSession(token, user);
    ref.read(apiClientProvider).setBearerToken(token);
    state = AuthState(user: user, token: token);
  }

  Future<void> logout() async {
    await ref.read(sessionStorageProvider).clear();
    ref.read(apiClientProvider).setBearerToken(null);
    state = const AuthState();
  }
}

final providerServiceProvider = Provider<ProviderService>(
    (ref) => ProviderService(ref.read(apiClientProvider)));

/// Providers distants (optionnel)
final remoteProvidersFutureProvider =
    FutureProvider<List<ServiceProvider>>((ref) async {
  final svc = ref.read(providerServiceProvider);
  final filters = ref.watch(searchFiltersProvider);
  final list = await svc.list(
    category: filters.category == 'Tous' ? null : filters.category,
    minRating: filters.minRating > 0 ? filters.minRating : null,
    q: filters.searchQuery.isNotEmpty ? filters.searchQuery : null,
  );
  return list.map((e) => providerFromApi(e as Map<String, dynamic>)).toList();
});

/// Provider pour les réservations de l'utilisateur
final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Booking>>((ref) {
  return BookingsNotifier();
});

/// Notifier pour gérer les réservations
class BookingsNotifier extends StateNotifier<List<Booking>> {
  BookingsNotifier() : super(const []);

  /// Ajouter une nouvelle réservation
  void addBooking(Booking booking) {
    state = [...state, booking];
  }

  /// Mettre à jour le statut d'une réservation
  void updateBookingStatus(String bookingId, BookingStatus status) {
    state = [
      for (final booking in state)
        if (booking.id == bookingId)
          booking.copyWith(
            status: status,
            completedAt:
                status == BookingStatus.completed ? DateTime.now() : null,
          )
        else
          booking,
    ];
  }

  /// Annuler une réservation
  void cancelBooking(String bookingId) {
    updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  /// Obtenir les réservations par statut
  List<Booking> getBookingsByStatus(BookingStatus status) {
    return state.where((booking) => booking.status == status).toList();
  }
}

/// Provider pour les filtres de recherche
final searchFiltersProvider =
    StateNotifierProvider<SearchFiltersNotifier, SearchFilters>((ref) {
  return SearchFiltersNotifier();
});

/// Classe pour les filtres de recherche
class SearchFilters {
  final String category;
  final double maxDistance;
  final double minRating;
  final String searchQuery;

  SearchFilters({
    this.category = 'Tous',
    this.maxDistance = 10.0,
    this.minRating = 0.0,
    this.searchQuery = '',
  });

  SearchFilters copyWith({
    String? category,
    double? maxDistance,
    double? minRating,
    String? searchQuery,
  }) {
    return SearchFilters(
      category: category ?? this.category,
      maxDistance: maxDistance ?? this.maxDistance,
      minRating: minRating ?? this.minRating,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier pour les filtres de recherche
class SearchFiltersNotifier extends StateNotifier<SearchFilters> {
  SearchFiltersNotifier() : super(SearchFilters());

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updateMaxDistance(double distance) {
    state = state.copyWith(maxDistance: distance);
  }

  void updateMinRating(double rating) {
    state = state.copyWith(minRating: rating);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetFilters() {
    state = SearchFilters();
  }
}

/// Provider pour les prestataires filtrés
final filteredProvidersProvider = Provider<List<ServiceProvider>>((ref) {
  final providers = ref.watch(providersProvider);
  final filters = ref.watch(searchFiltersProvider);

  return providers.where((provider) {
    // Filtrer par catégorie
    if (filters.category != 'Tous' &&
        !provider.categories.contains(filters.category)) {
      return false;
    }

    // Filtrer par distance
    final distance = provider.distanceFrom(5.35, -4.02);
    if (distance > filters.maxDistance) {
      return false;
    }

    // Filtrer par note
    if (provider.rating < filters.minRating) {
      return false;
    }

    // Filtrer par recherche textuelle
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      if (!provider.name.toLowerCase().contains(query) &&
          !provider.categories
              .any((cat) => cat.toLowerCase().contains(query)) &&
          !provider.description.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }).toList();
});

/// Provider pour la localisation de l'utilisateur
final userLocationProvider = Provider<UserLocation>(
    (ref) => UserLocation(latitude: 5.35, longitude: -4.02));

/// Classe pour la localisation de l'utilisateur
class UserLocation {
  final double latitude;
  final double longitude;

  UserLocation({
    required this.latitude,
    required this.longitude,
  });
}

/// Provider pour les avis
final reviewsProvider =
    StateNotifierProvider<ReviewsNotifier, List<Review>>((ref) {
  return ReviewsNotifier();
});

/// Notifier pour gérer les avis
class ReviewsNotifier extends StateNotifier<List<Review>> {
  ReviewsNotifier() : super(const []);

  /// Ajouter un nouvel avis
  void addReview(Review review) {
    state = [...state, review];
  }

  /// Obtenir les avis pour un prestataire
  List<Review> getReviewsForProvider(String providerId) {
    return state.where((review) => review.providerId == providerId).toList();
  }

  /// Calculer la note moyenne d'un prestataire
  double getAverageRatingForProvider(String providerId) {
    final providerReviews = getReviewsForProvider(providerId);
    if (providerReviews.isEmpty) return 0.0;

    final sum =
        providerReviews.fold<double>(0, (sum, review) => sum + review.rating);
    return sum / providerReviews.length;
  }
}

/// Provider pour obtenir un prestataire par ID
final providerByIdProvider =
    Provider.family<ServiceProvider?, String>((ref, id) {
  final providers = ref.watch(remoteProvidersFutureProvider).maybeWhen(
        data: (list) => list,
        orElse: () => const <ServiceProvider>[],
      );
  try {
    return providers.firstWhere((p) => p.id == id);
  } catch (e) {
    return null;
  }
});
