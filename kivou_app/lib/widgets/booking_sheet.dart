import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingInput {
  final DateTime scheduledAt;
  final double durationHours;
  final String? notes;
  final String serviceCategory;
  const BookingInput({
    required this.scheduledAt,
    required this.durationHours,
    required this.serviceCategory,
    this.notes,
  });
}

Future<BookingInput?> showBookingSheet({
  required BuildContext context,
  required String serviceCategory,
  String? initialNotes,
  double initialDurationHours = 1.0,
  DateTime? initialDateTime,
  double? pricePerHour,
}) {
  return showModalBottomSheet<BookingInput>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _BookingSheet(
      serviceCategory: serviceCategory,
      initialNotes: initialNotes,
      initialDurationHours: initialDurationHours,
      initialDateTime:
          initialDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      pricePerHour: pricePerHour,
    ),
  );
}

class _BookingSheet extends StatefulWidget {
  final String serviceCategory;
  final String? initialNotes;
  final double initialDurationHours;
  final DateTime initialDateTime;
  final double? pricePerHour;
  const _BookingSheet({
    required this.serviceCategory,
    this.initialNotes,
    required this.initialDurationHours,
    required this.initialDateTime,
    this.pricePerHour,
  });
  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late DateTime _date;
  late TimeOfDay _time;
  late double _duration;
  late TextEditingController _notesCtrl;
  @override
  void initState() {
    super.initState();
    _date = DateTime(widget.initialDateTime.year, widget.initialDateTime.month,
        widget.initialDateTime.day);
    _time = TimeOfDay.fromDateTime(widget.initialDateTime);
    _duration = widget.initialDurationHours;
    _notesCtrl = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at =
        DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final total = (widget.pricePerHour ?? 0) * _duration;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Commander',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(widget.serviceCategory, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Text('Date: ${DateFormat.yMd().format(_date)}')),
                TextButton(onPressed: _pickDate, child: const Text('Modifier')),
              ]),
              Row(children: [
                Expanded(child: Text('Heure: ${_time.format(context)}')),
                TextButton(onPressed: _pickTime, child: const Text('Modifier')),
              ]),
              Row(children: [
                const Text('Durée'),
                const Spacer(),
                Text('${_duration.toStringAsFixed(1)} h')
              ]),
              Slider(
                  value: _duration,
                  min: 1,
                  max: 8,
                  divisions: 14,
                  onChanged: (v) => setState(() => _duration = v)),
              TextField(
                controller: _notesCtrl,
                decoration:
                    const InputDecoration(labelText: 'Notes (optionnel)'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              if (widget.pricePerHour != null) ...[
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total estimé'),
                      Text(total.toStringAsFixed(0)),
                    ]),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    final input = BookingInput(
                      scheduledAt: at,
                      durationHours: _duration,
                      notes: _notesCtrl.text.trim().isEmpty
                          ? null
                          : _notesCtrl.text.trim(),
                      serviceCategory: widget.serviceCategory,
                    );
                    Navigator.of(context).pop(input);
                  },
                  label: const Text('Confirmer'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }
}
