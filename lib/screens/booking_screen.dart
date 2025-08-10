import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../providers/app_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(providerByIdProvider(widget.providerId));
    if (provider == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Réserver')),
          body: const Center(child: Text('Prestataire introuvable')));
    }
    service = service.isEmpty
        ? (provider.categories.isNotEmpty
            ? provider.categories.first
            : 'Service')
        : service;
    final total = provider.pricePerHour * duration;

    return Scaffold(
      appBar: AppBar(title: Text('Réserver ${provider.name}')),
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
          const Text('2) Options / date / heure'),
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
            onPressed: () => _confirm(total),
            child: const Text('3) Confirmer (paiement simulé)'),
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
    final id = 'b${DateTime.now().millisecondsSinceEpoch}';
    final at =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final booking = Booking(
      id: id,
      userId: 'user1',
      providerId: widget.providerId,
      serviceCategory: service,
      serviceDescription: service,
      scheduledAt: at,
      duration: duration,
      totalPrice: total,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );
    ref.read(bookingsProvider.notifier).addBooking(booking);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation créée (simulation)')));
      Navigator.of(context).pop();
    }
  }
}
