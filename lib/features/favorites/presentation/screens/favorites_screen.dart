import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/utils/amap_route_launcher.dart';
import 'package:emap_hangzhou/features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';

/// Favorites tab — lists all saved places with actions.
///
/// Delegates all logic to [FavoritesViewModel]. Widgets are purely
/// presentational.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesViewModel>().loadPlaces();
    });
  }

  Future<void> _deletePlace(PlaceEntity place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text('Delete "${place.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<FavoritesViewModel>().deletePlace(place.id);
    }
  }

  Future<void> _buildRoute(PlaceEntity place) async {
    await AmapRouteLauncher.launch(
      latitude: place.latitude,
      longitude: place.longitude,
      name: place.title,
    );
  }

  void _openOnMap(PlaceEntity place) {
    // Tell the map ViewModel to center on this place.
    context.read<MapViewModel>().navigateToPlace(
      latitude: place.latitude,
      longitude: place.longitude,
    );
    // Switch to the map tab.
    context.goNamed('map');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.places.isEmpty
          ? const Center(
              child: Text(
                'No saved places yet.\nTap the map to add one!',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.places.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, index) => _PlaceCard(
                place: vm.places[index],
                onDelete: () => _deletePlace(vm.places[index]),
                onBuildRoute: () => _buildRoute(vm.places[index]),
                onOpenOnMap: () => _openOnMap(vm.places[index]),
              ),
            ),
    );
  }
}

/// A single place item in the favorites list.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.onDelete,
    required this.onBuildRoute,
    required this.onOpenOnMap,
  });

  final PlaceEntity place;
  final VoidCallback onDelete;
  final VoidCallback onBuildRoute;
  final VoidCallback onOpenOnMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(place.type.icon, color: place.type.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: place.type.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    place.type.label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: place.type.color),
                  ),
                ),
              ],
            ),
            if (place.comment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                place.comment,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${place.latitude.toStringAsFixed(6)}, '
              '${place.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.map),
                  tooltip: 'Open on map',
                  onPressed: onOpenOnMap,
                ),
                IconButton(
                  icon: const Icon(Icons.directions),
                  tooltip: 'Build Route',
                  onPressed: onBuildRoute,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
