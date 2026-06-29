import 'package:flutter/material.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/utils/amap_route_launcher.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/sheet_widgets.dart';

class PoiSheet extends StatelessWidget {
  const PoiSheet({required this.poi, super.key});

  final PoiModel poi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = PlaceTypeUi.fromType(poi.category);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: SheetHandle()),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: type.color.withAlpha(AppConstants.poiSheetTintAlpha),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: type.color,
                    width: AppConstants.poiMarkerBorderWidth,
                  ),
                ),
                child: Icon(type.icon, color: type.color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poi.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: type.color.withAlpha(
                          AppConstants.poiSheetChipAlpha,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: type.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (poi.comment != null && poi.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(poi.comment!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.pin_drop, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${poi.lat.toStringAsFixed(6)}, ${poi.lng.toStringAsFixed(6)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final success = await AmapRouteLauncher.launch(
                latitude: poi.lat,
                longitude: poi.lng,
                name: poi.name,
              );
              if (!context.mounted || success) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AMap is not installed')),
              );
            },
            icon: const Icon(Icons.directions),
            label: const Text('Build Route'),
          ),
        ],
      ),
    );
  }
}
