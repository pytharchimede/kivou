import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/provider_detail_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/owner_orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/provider_registration_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(
    ProviderScope(
      child: KivouApp(),
    ),
  );
}

class KivouApp extends ConsumerWidget {
  const KivouApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      builder: (context, state) => const OrdersScreen(),
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
  ],
);
