import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/utils/coordinate_utils.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';

class PoiMapView extends StatefulWidget {
  const PoiMapView({
    required this.mapController,
    required this.initialCenter,
    required this.pois,
    required this.userPosition,
    required this.onPoiTap,
    super.key,
  });

  final MapController mapController;
  final LatLng initialCenter;
  final List<PoiModel> pois;
  final LatLng? userPosition;
  final ValueChanged<PoiModel> onPoiTap;

  @override
  State<PoiMapView> createState() => _PoiMapViewState();
}

class _PoiMapViewState extends State<PoiMapView> {
  static const _poiMarkerSize = Size.square(AppConstants.poiMarkerSize);

  List<PoiModel>? _cachedPois;
  List<Marker> _cachedPoiMarkers = const [];

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter,
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
            markers: _poiMarkers(widget.pois),
            builder: _buildClusterMarker,
          ),
        ),
        if (widget.userPosition != null)
          MarkerLayer(markers: [_buildUserMarker(widget.userPosition!)]),
      ],
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
      point: LatLng(poi.lat, poi.lng),
      width: _poiMarkerSize.width,
      height: _poiMarkerSize.height,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => widget.onPoiTap(poi),
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

class _PoiPin extends StatelessWidget {
  const _PoiPin({required this.type});

  final PlaceType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.poiMarkerSize,
      height: AppConstants.poiMarkerSize,
      decoration: BoxDecoration(
        color: type.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(55),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: Icon(type.icon, color: Colors.white, size: 24)),
    );
  }
}
