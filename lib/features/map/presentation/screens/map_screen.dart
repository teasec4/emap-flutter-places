import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/add_place_sheet.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_detail_sheet.dart';

/// Map tab — displays an interactive map with saved place markers.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  LatLng _currentCenter = AppConstants.defaultMapCenter;
  bool _locationGranted = false;

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
    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      _showLocationError('Location services are disabled.');
      return;
    }

    // Check permission
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
          setState(() {
            _currentCenter = LatLng(position.latitude, position.longitude);
          });
          _mapController.move(_currentCenter, AppConstants.defaultZoom);
        }
      } catch (_) {
        // GPS unavailable — map stays at default center
      }
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  void _handleNavigateTarget(MapViewModel vm) {
    final target = vm.consumeNavigateTarget();
    if (target != null) {
      _mapController.move(target, AppConstants.placeZoom);
    }
  }

  void _onTap(LatLng position) {
    _showAddPlaceSheet(position);
  }

  void _onMarkerTap(PlaceEntity place) {
    _showPlaceDetailSheet(place);
  }

  void _showAddPlaceSheet(LatLng position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddPlaceSheet(
        latitude: position.latitude,
        longitude: position.longitude,
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
              initialCenter: _currentCenter,
              initialZoom: AppConstants.defaultZoom,
              onTap: (_, position) => _onTap(position),
            ),
            children: [
              TileLayer(
                // ESRI World Street Map — global CDN, usually not blocked
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.emap_hangzhou',
                subdomains: const [],
              ),
              MarkerLayer(markers: vm.places.map(_buildMarker).toList()),
            ],
          ),
          // "My Location" button
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: () async {
                if (_locationGranted) {
                  try {
                    final position = await Geolocator.getCurrentPosition();
                    _mapController.move(
                      LatLng(position.latitude, position.longitude),
                      AppConstants.defaultZoom,
                    );
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

  Marker _buildMarker(PlaceEntity place) {
    return Marker(
      point: place.latLng,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _onMarkerTap(place),
        child: const Icon(Icons.location_on, color: Colors.red, size: 36),
      ),
    );
  }
}
