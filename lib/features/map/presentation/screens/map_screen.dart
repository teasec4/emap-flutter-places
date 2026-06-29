import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/utils/amap_route_launcher.dart';
import 'package:emap_hangzhou/core/utils/coordinate_utils.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  LatLng? _userPosition;
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<MapViewModel>();
      if (vm.initialPosition != null) {
        setState(() {
          _userPosition = vm.initialPosition;
          _locationGranted = true;
        });
        _mapController.move(
          CoordinateUtils.wgs84ToGcj02(vm.initialPosition!),
          AppConstants.defaultZoom,
        );
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onPoiTap(PoiModel poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.6,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          child: _PoiSheet(poi: poi),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    final center = _userPosition != null
        ? CoordinateUtils.wgs84ToGcj02(_userPosition!)
        : CoordinateUtils.wgs84ToGcj02(AppConstants.defaultMapCenter);

    // Show server error if any
    if (vm.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server: ${vm.error}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => context.read<MapViewModel>().loadPois(),
              ),
            ),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: AppConstants.defaultZoom,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://webrd0{s}.is.autonavi.com/appmaptile'
                    '?lang=zh_cn&size=1&scale=1&style=8'
                    '&x={x}&y={y}&z={z}',
                subdomains: const ['1', '2', '3', '4'],
                maxNativeZoom: 18,
                userAgentPackageName: 'com.example.emap_hangzhou',
              ),
              MarkerLayer(
                markers: [
                  ...vm.pois.map(_buildPoiMarker),
                  if (_userPosition != null) _buildUserMarker(),
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: () async {
                if (_locationGranted) {
                  try {
                    final pos = await Geolocator.getCurrentPosition();
                    final wgs = LatLng(pos.latitude, pos.longitude);
                    setState(() => _userPosition = wgs);
                    _mapController.move(
                      CoordinateUtils.wgs84ToGcj02(wgs),
                      AppConstants.defaultZoom,
                    );
                  } catch (_) {}
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildPoiMarker(PoiModel poi) {
    final type = PlaceTypeUi.fromCategory(poi.category);
    // Server stores GCJ-02 — no conversion needed
    return Marker(
      point: LatLng(poi.lat, poi.lng),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => _onPoiTap(poi),
        child: Container(
          decoration: BoxDecoration(
            color: type.color.withAlpha(40),
            shape: BoxShape.circle,
            border: Border.all(color: type.color, width: 2),
          ),
          child: Icon(type.icon, color: type.color, size: 28),
        ),
      ),
    );
  }

  Marker _buildUserMarker() {
    final gcj = CoordinateUtils.wgs84ToGcj02(_userPosition!);
    return Marker(
      point: gcj,
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          color: Colors.blue,
        ),
      ),
    );
  }
}

class _PoiSheet extends StatelessWidget {
  const _PoiSheet({required this.poi});
  final PoiModel poi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = PlaceTypeUi.fromCategory(poi.category);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: type.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: type.color, width: 2),
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
                        color: type.color.withAlpha(25),
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
          if (poi.city != null && poi.city!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_city, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(poi.city!, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => AmapRouteLauncher.launch(
              latitude: poi.lat,
              longitude: poi.lng,
              name: poi.name,
            ),
            icon: const Icon(Icons.directions),
            label: const Text('Build Route'),
          ),
        ],
      ),
    );
  }
}
