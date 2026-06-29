import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/utils/coordinate_utils.dart';
import 'package:emap_hangzhou/features/map/domain/services/place_recommendation_service.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/poi_map_view.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/poi_sheet.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/recommendations_overlay.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

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

    final recommendedPlaces = PlaceRecommendationService.nearbyPlaces(
      userPosition: vm.userPosition,
      pois: vm.pois,
    );

    return Scaffold(
      body: Stack(
        children: [
          PoiMapView(
            mapController: _mapController,
            initialCenter: center,
            pois: vm.pois,
            userPosition: vm.userPosition,
            onPoiTap: _onPoiTap,
          ),
          Positioned(
            right: 16,
            top: 16,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'my_location',
                onPressed: _refreshLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
          RecommendationsOverlay(
            places: recommendedPlaces,
            hasUserPosition: vm.userPosition != null,
            onRefreshLocation: _refreshLocation,
            onPlaceTap: _selectRecommendedPlace,
          ),
        ],
      ),
    );
  }

  void _selectRecommendedPlace(PoiModel poi) {
    _moveToMapPoint(_poiMapPoint(poi), AppConstants.selectedPlaceZoom);
    _onPoiTap(poi);
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

  // The public POI API stores AMap/GCJ-02 coordinates. Draw them on AMap
  // tiles as-is; convert only for GPS/user coordinates.
  LatLng _poiMapPoint(PoiModel poi) => LatLng(poi.lat, poi.lng);

  void _moveToUser(LatLng position) {
    _moveToMapPoint(
      CoordinateUtils.wgs84ToGcj02(position),
      AppConstants.defaultZoom,
    );
  }

  void _moveToMapPoint(LatLng point, double zoom) {
    _mapController.move(point, zoom, offset: const Offset(0, -120));
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
          child: PoiSheet(poi: poi),
        ),
      ),
    );
  }
}
