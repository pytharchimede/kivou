import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/upload_service.dart';
import '../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
          tooltip: 'Accueil',
        ),
        title: const Text('Mon profil'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Se déconnecter',
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user),
          ),
          if (user == null)
            const SliverToBoxAdapter(child: _LoggedOutCard())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ActionCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Mes commandes',
                    subtitle: 'Historique, suivi et reçus',
                    onTap: () => context.go('/orders'),
                  ),
                  const SizedBox(height: 12),
                  _OwnerOrdersAction(),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Devenir prestataire',
                    subtitle: 'Créez votre fiche et recevez des clients',
                    onTap: () => context.go('/become-provider'),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.settings_outlined,
                    title: 'Paramètres',
                    subtitle: 'Notifications, sécurité, préférences',
                    onTap: () {},
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final Map<String, dynamic>? user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    String _norm(String? u) {
      if (u == null || u.isEmpty) return '';
      if (u.startsWith('http://') || u.startsWith('https://')) return u;
      if (u.startsWith('/')) return 'https://fidest.ci' + u;
      return u;
    }

    final avatarUrl = _norm(user?['avatar_url']?.toString());
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primary.withOpacity(.15),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              if (user != null)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: IconButton(
                    tooltip: 'Changer la photo',
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: Size(32, 32)),
                    icon: const Icon(Icons.photo_camera, size: 18),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 85);
                      if (picked == null) return;
                      final file = File(picked.path);
                      final token = ref.read(authStateProvider).token;
                      try {
                        final url = await UploadService()
                            .uploadUserAvatar(file, bearerToken: token);
                        await ref
                            .read(authStateProvider.notifier)
                            .updateAvatar(url);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Photo de profil mise à jour')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')));
                        }
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null
                      ? (user!['name']?.toString() ?? 'Utilisateur')
                      : 'Bienvenue sur KIVOU',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  user != null
                      ? (user!['email']?.toString() ?? '')
                      : 'Connectez-vous pour profiter de tous les services',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onPrimaryContainer.withOpacity(.8)),
                ),
              ],
            ),
          ),
          if (user == null)
            FilledButton(
              onPressed: () => GoRouter.of(context).go('/auth'),
              child: const Text('Se connecter'),
            ),
        ],
      ),
    );
  }
}

class _LoggedOutCard extends StatelessWidget {
  const _LoggedOutCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Créez un compte', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Suivez vos commandes, échangez avec les prestataires et gagnez du temps.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => GoRouter.of(context).go('/auth'),
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => GoRouter.of(context).go('/auth'),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text("S'inscrire"),
                  ),
                ),
              ])
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerOrdersAction extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(ownerPendingCountProvider);
    return Stack(
      children: [
        _ActionCard(
          icon: Icons.inbox_outlined,
          title: 'Commandes reçues (prestataire)',
          subtitle: 'Accepter ou refuser les demandes',
          onTap: () => context.go('/owner-orders'),
        ),
        if (pending > 0)
          Positioned(
            right: 16,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pending > 99 ? '99+' : '$pending',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey[700])),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
