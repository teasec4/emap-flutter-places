import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/utils/amap_route_launcher.dart';
import 'package:emap_hangzhou/core/utils/coordinate_utils.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _poiMarkerSize = Size(32, 40);

  late final MapController _mapController;
  List<PoiModel>? _cachedPois;
  List<Marker> _cachedPoiMarkers = const [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final position = context.read<MapViewModel>().userPosition;
      if (position != null) _moveToUser(position);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    final center = vm.userPosition != null
        ? CoordinateUtils.wgs84ToGcj02(vm.userPosition!)
        : CoordinateUtils.wgs84ToGcj02(AppConstants.defaultMapCenter);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: AppConstants.defaultZoom,
              maxZoom: AppConstants.tileMaxZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.amapTileUrlTemplate,
                subdomains: AppConstants.amapTileSubdomains,
                maxNativeZoom: AppConstants.amapTileMaxNativeZoom,
                userAgentPackageName: AppConstants.tileUserAgentPackageName,
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 50,
                  size: const Size(50, 50),
                  markers: _poiMarkers(vm.pois),
                  builder: _buildClusterMarker,
                ),
              ),
              if (vm.userPosition != null)
                MarkerLayer(markers: [_buildUserMarker(vm.userPosition!)]),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: _refreshLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshLocation() async {
    final vm = context.read<MapViewModel>();
    final foundLocation = await vm.refreshLocation();
    if (!mounted) return;

    final position = vm.userPosition;
    if (foundLocation && position != null) {
      _moveToUser(position);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Location is unavailable')));
  }

  void _moveToUser(LatLng position) {
    _mapController.move(
      CoordinateUtils.wgs84ToGcj02(position),
      AppConstants.defaultZoom,
    );
  }

  List<Marker> _poiMarkers(List<PoiModel> pois) {
    if (identical(_cachedPois, pois)) return _cachedPoiMarkers;

    _cachedPois = pois;
    _cachedPoiMarkers = pois.map(_buildPoiMarker).toList(growable: false);
    return _cachedPoiMarkers;
  }

  Widget _buildClusterMarker(BuildContext context, List<Marker> markers) {
    final counts = <PlaceType, int>{};
    for (final marker in markers) {
      final key = marker.key;
      final category = key is ValueKey<_PoiMarkerKey>
          ? key.value.category
          : PlaceType.other;
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${markers.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 3,
            runSpacing: 1,
            alignment: WrapAlignment.center,
            children: counts.keys
                .map((type) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: type.color,
                      shape: BoxShape.circle,
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Marker _buildPoiMarker(PoiModel poi) {
    final type = PlaceTypeUi.fromType(poi.category);
    return Marker(
      key: ValueKey(_PoiMarkerKey(type, poi.id)),
      point: CoordinateUtils.wgs84ToGcj02(LatLng(poi.lat, poi.lng)),
      width: _poiMarkerSize.width,
      height: _poiMarkerSize.height,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () => _onPoiTap(poi),
        child: _PoiPin(type: type),
      ),
    );
  }

  Marker _buildUserMarker(LatLng wgs) {
    return Marker(
      point: CoordinateUtils.wgs84ToGcj02(wgs),
      width: AppConstants.userMarkerSize,
      height: AppConstants.userMarkerSize,
      alignment: Alignment.center,
      child: Container(
        width: AppConstants.userMarkerSize,
        height: AppConstants.userMarkerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: AppConstants.userMarkerBorderWidth,
          ),
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
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: _PoiSheet(poi: poi),
        ),
      ),
    );
  }
}

class _PoiMarkerKey {
  const _PoiMarkerKey(this.category, this.id);

  final PlaceType category;
  final String id;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _PoiMarkerKey && other.category == category && other.id == id;
  }

  @override
  int get hashCode => Object.hash(category, id);
}

class _PoiSheet extends StatelessWidget {
  const _PoiSheet({required this.poi});

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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(
                  AppConstants.sheetHandleAlpha,
                ),
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

class _PoiPin extends StatelessWidget {
  const _PoiPin({required this.type});

  final PlaceType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: type.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(35),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: Icon(type.icon, color: Colors.white, size: 18)),
        ),
        CustomPaint(
          size: const Size(10, 7),
          painter: _TrianglePainter(color: type.color),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      ui.Path()
        ..moveTo(size.width / 2, size.height)
        ..lineTo(0, 0)
        ..lineTo(size.width, 0)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
