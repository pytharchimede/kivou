import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
// import '../models/booking.dart';
import '../providers/app_providers.dart';
import '../services/booking_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String providerId;
  const BookingScreen({super.key, required this.providerId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  String service = '';
  DateTime date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
  double duration = 2.0;
  bool _submitting = false;
  final TextEditingController _detailsCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(providerByIdProvider(widget.providerId));
    if (provider == null) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Réserver'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: 'Accueil',
              onPressed: () => context.go('/home'),
            ),
          ),
          body: const Center(child: Text('Prestataire introuvable')));
    }
    service = service.isEmpty
        ? (provider.categories.isNotEmpty
            ? provider.categories.first
            : 'Service')
        : service;
    final total = provider.pricePerHour * duration;

    return Scaffold(
      appBar: AppBar(
        title: Text('Réserver ${provider.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Accueil',
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1) Choisir le service'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: service,
            items: [service, ...provider.categories]
                .toSet()
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => service = v ?? service),
          ),
          const SizedBox(height: 16),
          const Text('2) Détails de la commande (optionnel)'),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Expliquez brièvement votre besoin (ex: nombre de pièces, disponibilité, précisions…)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('3) Options / date / heure'),
          Row(children: [
            Expanded(child: Text('Date: ${DateFormat.yMd().format(date)}')),
            TextButton(onPressed: _pickDate, child: const Text('Modifier')),
          ]),
          Row(children: [
            Expanded(child: Text('Heure: ${time.format(context)}')),
            TextButton(onPressed: _pickTime, child: const Text('Modifier')),
          ]),
          Row(children: [
            const Text('Durée'),
            const Spacer(),
            Text('${duration.toStringAsFixed(1)} h')
          ]),
          Slider(
              value: duration,
              min: 1,
              max: 8,
              divisions: 14,
              onChanged: (v) => setState(() => duration = v)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total estimé',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${total.toStringAsFixed(2)} €'),
          ]),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitting ? null : () => _confirm(total),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('4) Confirmer (sans paiement)'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: time);
    if (t != null) setState(() => time = t);
  }

  void _confirm(double total) {
    if (_submitting) return;
    setState(() => _submitting = true);
    final auth = ref.read(authStateProvider);
    final at =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter.')));
      context.go('/auth');
      return;
    }
    final svc = BookingService(ref.read(apiClientProvider));
    svc
        .create(
      userId: 0, // ignored if token present
      providerId: int.tryParse(widget.providerId) ?? 0,
      serviceCategory: service,
      description: (_detailsCtrl.text.trim().isNotEmpty)
          ? _detailsCtrl.text.trim()
          : service,
      scheduledAt: at,
      duration: duration,
      totalPrice: total,
    )
        .then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Réservation créée.')));
      context.go('/home');
    }).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }).whenComplete(() {
      if (mounted) setState(() => _submitting = false);
    });
  }
}
