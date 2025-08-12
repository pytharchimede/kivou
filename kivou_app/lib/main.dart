import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push_service.dart';
import 'providers/app_providers.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/provider_detail_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/owner_orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/provider_registration_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_room_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.initializeFirebase();
  runApp(const ProviderScope(child: KivouApp()));
}

class KivouApp extends ConsumerStatefulWidget {
  const KivouApp({super.key});

  @override
  ConsumerState<KivouApp> createState() => _KivouAppState();
}

class _KivouAppState extends ConsumerState<KivouApp> {
  @override
  void initState() {
    super.initState();
    // Enregistrer callback pour rafraîchissement de token FCM
    PushService.setOnTokenRefresh(() async {
      final auth = ref.read(authStateProvider);
      if (auth.isAuthenticated) {
        await ref.read(pushServiceProvider).registerFcmToken();
      }
    });
    // Navigation au tap sur notification
    PushService.setOnNotificationTap((data) {
      if (!mounted) return;
      final type = (data['type'] ?? '').toString();
      if (type == 'chat') {
        final idStr = (data['conversation_id'] ?? '').toString();
        final id = int.tryParse(idStr);
        if (id != null && id > 0) {
          _router.go('/chat/$id');
          return;
        }
      }
      if (type == 'booking') {
        // Déterminer l'onglet: côté prestataire (owner) ou demandeur (client)
        final action = (data['action'] ?? '').toString();
        // Heuristique: created -> prestataire (notification au propriétaire),
        // confirmed/cancelled/completed -> client.
        final tabIndex = (action == 'created') ? 1 : 0;
        _router.go('/orders', extra: tabIndex);
        return;
      }
      // Fallback: accueil
      _router.go('/home');
    });
    // Si l'utilisateur est déjà connecté au restore, enregistrer le token
    Future.microtask(() async {
      final auth = ref.read(authStateProvider);
      if (auth.isAuthenticated) {
        await ref.read(pushServiceProvider).registerFcmToken();
      }
    });
    // Si l’app est lancée depuis une notification (terminated state)
    Future.microtask(() async {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        final data = initial.data;
        final type = (data['type'] ?? '').toString();
        if (type == 'chat') {
          final idStr = (data['conversation_id'] ?? '').toString();
          final id = int.tryParse(idStr);
          if (id != null && id > 0) {
            if (!mounted) return;
            _router.go('/chat/$id');
            return;
          }
        }
        if (type == 'booking') {
          if (!mounted) return;
          final action = (data['action'] ?? '').toString();
          final tabIndex = (action == 'created') ? 1 : 0;
          _router.go('/orders', extra: tabIndex);
          return;
        }
        if (!mounted) return;
        _router.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KIVOU - Prestataires à domicile',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/provider/:id',
      name: 'provider',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProviderDetailScreen(providerId: id);
      },
    ),
    GoRoute(
      path: '/booking/:providerId',
      name: 'booking',
      builder: (context, state) {
        final providerId = state.pathParameters['providerId']!;
        return BookingScreen(providerId: providerId);
      },
    ),
    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (context, state) {
        int initialIndex = 0;
        final extra = state.extra;
        if (extra is int) {
          if (extra == 0 || extra == 1) initialIndex = extra;
        } else if (extra is Map) {
          final t = extra['tab'];
          if (t is int && (t == 0 || t == 1)) initialIndex = t;
        }
        return OrdersScreen(initialIndex: initialIndex);
      },
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/become-provider',
      name: 'become-provider',
      builder: (context, state) => const ProviderRegistrationScreen(),
    ),
    GoRoute(
      path: '/owner-orders',
      name: 'owner-orders',
      builder: (context, state) => const OwnerOrdersScreen(),
    ),
    GoRoute(
      path: '/chats',
      name: 'chats',
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      name: 'chat-room',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return ChatRoomScreen(conversationId: id);
      },
    ),
  ],
);
