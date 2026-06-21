import 'package:flutter/material.dart';

import 'package:emap_hangzhou/core/utils/amap_route_launcher.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';

/// Bottom sheet shown when the user taps an existing marker.
///
/// Displays title, comment, coordinates and a "Build Route" button that
/// launches AMap.
class PlaceDetailSheet extends StatelessWidget {
  const PlaceDetailSheet({super.key, required this.place});

  final PlaceEntity place;

  Future<void> _buildRoute() async {
    final success = await AmapRouteLauncher.launch(
      latitude: place.latitude,
      longitude: place.longitude,
      name: place.title,
    );

    if (!success) {
      // AMap not installed — url_launcher handles the platform dialog.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(place.title, style: Theme.of(context).textTheme.titleLarge),
          if (place.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(place.comment, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Text(
            '${place.latitude.toStringAsFixed(6)}, '
            '${place.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${_formatDate(place.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _buildRoute,
            icon: const Icon(Icons.directions),
            label: const Text('Build Route'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
        '-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}'
        ':${dt.minute.toString().padLeft(2, '0')}';
  }
}
