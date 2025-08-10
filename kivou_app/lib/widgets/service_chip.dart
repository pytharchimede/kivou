import 'package:flutter/material.dart';

class ServiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const ServiceChip(
      {super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap?.call(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
