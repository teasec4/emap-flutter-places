import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/utils/coordinate_utils.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/add_place_sheet.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/map_search_bar.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_detail_sheet.dart';

/// Map tab — AMap tiles with GCJ-02/WGS-84 coordinate conversion.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  // Map center in GCJ-02 (AMap coordinate system).
  LatLng _centerGcj02 = CoordinateUtils.wgs84ToGcj02(
    AppConstants.defaultMapCenter,
  );
  bool _locationGranted = false;

  /// Current user position in WGS-84 (null until GPS fix).
  LatLng? _userPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().loadPlaces();
      _requestLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      _showLocationError('Location services are disabled.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      _showLocationError('Location permission denied permanently.');
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _locationGranted = true;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          // GPS returns WGS-84 → convert to GCJ-02 for AMap display
          final wgs = LatLng(position.latitude, position.longitude);
          final gcj = CoordinateUtils.wgs84ToGcj02(wgs);
          setState(() {
            _userPosition = wgs;
            _centerGcj02 = gcj;
          });
          _mapController.move(gcj, AppConstants.defaultZoom);
        }
      } catch (_) {}
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  void _onSearchResultSelected(String name, LatLng wgsPosition) {
    // Move map to the location (GCJ-02 for AMap display)
    final gcj = CoordinateUtils.wgs84ToGcj02(wgsPosition);
    _mapController.move(gcj, AppConstants.placeZoom);

    // Show add-place sheet with pre-filled name and WGS-84 coords
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddPlaceSheet(
        latitude: wgsPosition.latitude,
        longitude: wgsPosition.longitude,
        prefilledTitle: name,
      ),
    );
  }

  void _handleNavigateTarget(MapViewModel vm) {
    final target = vm.consumeNavigateTarget();
    if (target != null) {
      // Target is WGS-84 → convert to GCJ-02 for AMap display
      _mapController.move(
        CoordinateUtils.wgs84ToGcj02(target),
        AppConstants.placeZoom,
      );
    }
  }

  /// Map tap returns GCJ-02. Convert to WGS-84 for storage.
  void _onTap(LatLng gcjPosition) {
    final wgs = CoordinateUtils.gcj02ToWgs84(gcjPosition);
    _showAddPlaceSheet(wgs);
  }

  void _onMarkerTap(PlaceEntity place) {
    _showPlaceDetailSheet(place);
  }

  void _showAddPlaceSheet(LatLng wgsPosition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddPlaceSheet(
        latitude: wgsPosition.latitude,
        longitude: wgsPosition.longitude,
      ),
    );
  }

  void _showPlaceDetailSheet(PlaceEntity place) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (_) => PlaceDetailSheet(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    _handleNavigateTarget(vm);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerGcj02,
              initialZoom: AppConstants.defaultZoom,
              maxZoom: 19,
              onTap: (_, position) => _onTap(position),
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
                  ...vm.places.map(_buildMarker),
                  if (_userPosition != null) _buildUserMarker(),
                ],
              ),
            ],
          ),
          // Search bar at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MapSearchBar(onPlaceSelected: _onSearchResultSelected),
          ),
          // My Location button
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: () async {
                if (_locationGranted) {
                  try {
                    final position = await Geolocator.getCurrentPosition();
                    final wgs = LatLng(position.latitude, position.longitude);
                    final gcj = CoordinateUtils.wgs84ToGcj02(wgs);
                    setState(() => _userPosition = wgs);
                    _mapController.move(gcj, AppConstants.defaultZoom);
                  } catch (_) {}
                } else {
                  _requestLocation();
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  /// Marker position is WGS-84 → convert to GCJ-02 for AMap display.
  Marker _buildMarker(PlaceEntity place) {
    final gcj = CoordinateUtils.wgs84ToGcj02(place.latLng);
    return Marker(
      point: gcj,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _onMarkerTap(place),
        child: const Icon(Icons.place, color: Colors.red, size: 36),
      ),
    );
  }

  /// Blue dot for user's current location.
  Marker _buildUserMarker() {
    final gcj = CoordinateUtils.wgs84ToGcj02(_userPosition!);
    return Marker(
      point: gcj,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(60),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.circle, color: Colors.blue, size: 14),
        ),
      ),
    );
  }
}
