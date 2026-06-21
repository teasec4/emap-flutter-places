import 'package:flutter/material.dart';

import 'package:emap_hangzhou/core/utils/amap_route_launcher.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';

/// Bottom sheet shown when tapping an existing marker.
///
/// Displays type icon, title, comment, coordinates, and Build Route button.
class PlaceDetailSheet extends StatelessWidget {
  const PlaceDetailSheet({super.key, required this.place});

  final PlaceEntity place;

  Future<void> _buildRoute() async {
    await AmapRouteLauncher.launch(
      latitude: place.latitude,
      longitude: place.longitude,
      name: place.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Type icon + title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: place.type.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(place.type.icon, color: place.type.color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: place.type.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place.type.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: place.type.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (place.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(place.comment, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          // Coordinates
          Row(
            children: [
              const Icon(Icons.pin_drop, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${place.latitude.toStringAsFixed(6)}, '
                '${place.longitude.toStringAsFixed(6)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_fmt(place.createdAt), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _buildRoute,
            icon: const Icon(Icons.directions),
            label: const Text('Build Route'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
        '-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}'
        ':${dt.minute.toString().padLeft(2, '0')}';
  }
}
