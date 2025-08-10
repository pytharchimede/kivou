import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
            const SizedBox(height: 12),
            const Text('Utilisateur Test',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text('email@example.com',
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 18),
            ElevatedButton.icon(
                onPressed: () => context.go('/orders'),
                icon: const Icon(Icons.receipt),
                label: const Text('Mes commandes')),
            const SizedBox(height: 8),
            ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.switch_account),
                label: const Text('Mode prestataire (demo)')),
          ],
        ),
      ),
    );
  }
}
