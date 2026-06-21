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
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';

/// Map tab — AMap tiles with GCJ-02/WGS-84 coordinate conversion.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  LatLng _centerGcj02 = CoordinateUtils.wgs84ToGcj02(
    AppConstants.defaultMapCenter,
  );
  bool _locationGranted = false;
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
      _showSnack('Location services are disabled.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      _showSnack('Location permission denied permanently.');
      return;
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _locationGranted = true;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          final wgs = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _userPosition = wgs;
            _centerGcj02 = CoordinateUtils.wgs84ToGcj02(wgs);
          });
          _mapController.move(_centerGcj02, AppConstants.defaultZoom);
        }
      } catch (_) {}
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
    );
  }

  /// Search result selected — just move the map, don't auto-save.
  void _onSearchResultSelected(String name, LatLng wgsPos) {
    final gcj = CoordinateUtils.wgs84ToGcj02(wgsPos);
    _mapController.move(gcj, AppConstants.placeZoom);
  }

  void _handleNavigateTarget(MapViewModel vm) {
    final target = vm.consumeNavigateTarget();
    if (target != null) {
      _mapController.move(
        CoordinateUtils.wgs84ToGcj02(target),
        AppConstants.placeZoom,
      );
    }
  }

  /// Map tap returns GCJ-02. Convert to WGS-84 for storage.
  void _onTap(LatLng gcj) {
    final wgs = CoordinateUtils.gcj02ToWgs84(gcj);
    _showAddPlaceSheet(wgs);
  }

  void _onMarkerTap(PlaceEntity place) {
    _showPlaceDetailSheet(place);
  }

  void _showAddPlaceSheet(LatLng wgs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          AddPlaceSheet(latitude: wgs.latitude, longitude: wgs.longitude),
    );
  }

  void _showPlaceDetailSheet(PlaceEntity place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.75,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: PlaceDetailSheet(place: place),
        ),
      ),
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
              onTap: (_, p) => _onTap(p),
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
          // Bottom search panel
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: MapSearchBar(onPlaceSelected: _onSearchResultSelected),
          ),
          // My Location button
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: () async {
                if (_locationGranted) {
                  try {
                    final pos = await Geolocator.getCurrentPosition();
                    final wgs = LatLng(pos.latitude, pos.longitude);
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

  Marker _buildMarker(PlaceEntity place) {
    final gcj = CoordinateUtils.wgs84ToGcj02(place.latLng);
    return Marker(
      point: gcj,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => _onMarkerTap(place),
        child: Container(
          decoration: BoxDecoration(
            color: place.type.color.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: Icon(place.type.icon, color: place.type.color, size: 28),
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
