import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating; // 0..5
  final int? count;
  final Color? color;
  final double size;

  const RatingStars(
      {super.key,
      required this.rating,
      this.count,
      this.color,
      this.size = 16});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.amber;
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < full) {
            return Icon(Icons.star, color: c, size: size);
          }
          if (i == full && hasHalf) {
            return Icon(Icons.star_half, color: c, size: size);
          }
          return Icon(Icons.star_border, color: c, size: size);
        }),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text('(${count!})',
              style: TextStyle(fontSize: size * 0.8, color: Colors.grey[700])),
        ]
      ],
    );
  }
}
