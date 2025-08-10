import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/provider_service.dart';

class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  const ProviderRegistrationScreen({super.key});
  @override
  ConsumerState<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends ConsumerState<ProviderRegistrationScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cats = TextEditingController();
  final _price = TextEditingController(text: '100');
  bool loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _cats.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) {
      return const Scaffold(
          body: Center(child: Text('Veuillez vous connecter.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Devenir prestataire')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(children: [
            TextField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Nom du prestataire')),
            const SizedBox(height: 12),
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Téléphone')),
            const SizedBox(height: 12),
            TextField(
                controller: _cats,
                decoration: const InputDecoration(
                    labelText: 'Catégories (séparées par des virgules)')),
            const SizedBox(height: 12),
            TextField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Tarif horaire'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Enregistrer'),
              ),
            )
          ]),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      final svc = ref.read(providerServiceProvider);
      final cats = _cats.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await svc.registerProvider(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        categories: cats,
        pricePerHour: double.tryParse(_price.text) ?? 100,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil prestataire créé.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
