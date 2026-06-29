import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/utils/amap_route_launcher.dart';
import 'package:emap_hangzhou/core/utils/coordinate_utils.dart';
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
      if (!mounted) return;
      final vm = context.read<MapViewModel>();
      final initial = vm.initialPosition;
      if (initial != null) {
        setState(() {
          _userPosition = initial;
          _locationGranted = true;
        });
        _mapController.move(
          CoordinateUtils.wgs84ToGcj02(initial),
          AppConstants.defaultZoom,
        );
      } else {
        // Splash didn't get GPS — try again now
        _requestLocation();
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onPoiTap(PoiModel poi) {
    showModalBottomSheet<void>(
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

    if (vm.error != null) {
      // NOTE: this fires on every rebuild while error is non-null. See TODO
      // — should be wired through a one-shot listener instead.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server: ${vm.error}'),
            duration: AppConstants.errorSnackBarDuration,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => context.read<MapViewModel>().loadPois(),
            ),
          ),
        );
      });
    }

    final wgsCenter = _userPosition ?? AppConstants.defaultMapCenter;
    final mapCenter = CoordinateUtils.wgs84ToGcj02(wgsCenter);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
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
              onPressed: _onMyLocationPressed,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMyLocationPressed() async {
    if (!_locationGranted) {
      await _requestLocation();
      return;
    }
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

  Future<void> _requestLocation() async {
    final ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) {
      if (mounted) _snack('Turn on location services');
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) _snack('Location denied. Enable in Settings.');
      return;
    }
    if (perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always) {
      _locationGranted = true;
      try {
        final pos = await Geolocator.getCurrentPosition();
        final wgs = LatLng(pos.latitude, pos.longitude);
        setState(() => _userPosition = wgs);
        _mapController.move(
          CoordinateUtils.wgs84ToGcj02(wgs),
          AppConstants.defaultZoom,
        );
      } catch (_) {
        if (mounted) _snack('Could not get GPS fix');
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  Marker _buildPoiMarker(PoiModel poi) {
    final type = PlaceTypeUi.fromType(poi.category);
    // Server stores GCJ-02 — no conversion needed.
    return Marker(
      point: LatLng(poi.lat, poi.lng),
      width: AppConstants.poiMarkerSize,
      height: AppConstants.poiMarkerSize,
      child: GestureDetector(
        onTap: () => _onPoiTap(poi),
        child: Container(
          decoration: BoxDecoration(
            color: type.color.withValues(
              alpha: AppConstants.poiMarkerFillAlpha / 255,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: type.color,
              width: AppConstants.poiMarkerBorderWidth,
            ),
          ),
          child: Icon(type.icon, color: type.color, size: 28),
        ),
      ),
    );
  }

  Marker _buildUserMarker() => Marker(
    point: CoordinateUtils.wgs84ToGcj02(_userPosition!),
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
            color: Colors.black.withValues(alpha: 50 / 255),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        color: Colors.blue,
      ),
    ),
  );
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
                color: theme.colorScheme.onSurface.withValues(
                  alpha: AppConstants.sheetHandleAlpha / 255,
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
                  color: type.color.withValues(
                    alpha: AppConstants.poiSheetTintAlpha / 255,
                  ),
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
                        color: type.color.withValues(
                          alpha: AppConstants.poiSheetChipAlpha / 255,
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
