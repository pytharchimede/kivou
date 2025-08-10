import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kivou_app/models/service_provider.dart';
import 'package:kivou_app/widgets/rating_stars.dart';
import 'package:kivou_app/widgets/quick_call_sheet.dart';

class ProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final double? userLat;
  final double? userLng;

  const ProviderCard(
      {super.key, required this.provider, this.userLat, this.userLng});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dist = (userLat != null && userLng != null)
        ? provider.distanceFrom(userLat!, userLng!)
        : null;
    final distanceText = dist != null ? '${dist.toStringAsFixed(1)} km' : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/provider/${provider.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    provider.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[200],
                        child:
                            const Center(child: Icon(Icons.image, size: 48))),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(provider.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white)),
                    ]),
                  ),
                ),
                if (distanceText != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.place, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(distanceText,
                            style: const TextStyle(color: Colors.white)),
                      ]),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(provider.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone),
                        tooltip: 'Contacter',
                        onPressed: () => QuickCallSheet.show(context,
                            phoneNumber: provider.phone,
                            message: 'Bonjour ${provider.name}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(provider.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  RatingStars(
                      rating: provider.rating, count: provider.reviewsCount),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: -8,
                    children: [
                      ...provider.categories.take(3).map((s) => Chip(
                          label: Text(s),
                          visualDensity: VisualDensity.compact)),
                      if (provider.categories.length > 3)
                        Chip(
                            label: Text('+${provider.categories.length - 3}'),
                            visualDensity: VisualDensity.compact),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_money,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                          'à partir de ${provider.pricePerHour.toStringAsFixed(0)} FCFA/h'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/booking/${provider.id}'),
                        icon:
                            const Icon(Icons.calendar_today_rounded, size: 18),
                        label: const Text('Réserver'),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
