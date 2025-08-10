import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Vous n\'êtes pas connecté(e).'),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: () => context.go('/auth'),
                        child: const Text('Se connecter / S\'inscrire')),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                      radius: 42, child: Icon(Icons.person, size: 42)),
                  const SizedBox(height: 12),
                  Text(user['name']?.toString() ?? 'Utilisateur',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(user['email']?.toString() ?? '',
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                      onPressed: () => context.go('/orders'),
                      icon: const Icon(Icons.receipt),
                      label: const Text('Mes commandes')),
                  const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => context.go('/become-provider'),
                icon: const Icon(Icons.work_outline),
                label: const Text('Devenir prestataire')),
              const SizedBox(height: 8),
                  ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(authStateProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter')),
                ],
              ),
      ),
    );
  }
}
