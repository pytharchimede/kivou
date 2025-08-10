import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  const PrimaryButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.icon,
      this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded),
      label: Text(label),
    );
    if (expanded) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }
}
