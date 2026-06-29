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
  static const _poiMarkerSize = Size.square(AppConstants.poiMarkerSize);

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

    final recommendedPlaces = _recommendedPlaces(
      userPosition: vm.userPosition,
      pois: vm.pois,
    );

    return Scaffold(
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
            top: 16,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'my_location',
                onPressed: _refreshLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
          _RecommendationsOverlay(
            places: recommendedPlaces,
            hasUserPosition: vm.userPosition != null,
            onRefreshLocation: _refreshLocation,
            onPlaceTap: _selectRecommendedPlace,
          ),
        ],
      ),
    );
  }

  List<_RecommendedPlace> _recommendedPlaces({
    required LatLng? userPosition,
    required List<PoiModel> pois,
  }) {
    if (userPosition == null) return const [];

    const distance = Distance();
    final places = pois
        .map((poi) {
          final meters = distance.as(
            LengthUnit.Meter,
            userPosition,
            _poiGpsPoint(poi),
          );
          return _RecommendedPlace(poi: poi, distanceMeters: meters);
        })
        .where((place) {
          return place.distanceMeters <= AppConstants.nearbyPlacesRadiusMeters;
        })
        .toList(growable: false);

    return [...places]..sort(
      (left, right) => left.distanceMeters.compareTo(right.distanceMeters),
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
  // tiles as-is; convert only for GPS-distance calculations.
  LatLng _poiMapPoint(PoiModel poi) => LatLng(poi.lat, poi.lng);

  LatLng _poiGpsPoint(PoiModel poi) {
    return CoordinateUtils.gcj02ToWgs84(_poiMapPoint(poi));
  }

  void _moveToUser(LatLng position) {
    _moveToMapPoint(
      CoordinateUtils.wgs84ToGcj02(position),
      AppConstants.defaultZoom,
    );
  }

  void _moveToMapPoint(LatLng point, double zoom) {
    _mapController.move(point, zoom, offset: const Offset(0, -120));
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
      point: _poiMapPoint(poi),
      width: _poiMarkerSize.width,
      height: _poiMarkerSize.height,
      alignment: Alignment.center,
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

class _RecommendedPlace {
  const _RecommendedPlace({required this.poi, required this.distanceMeters});

  final PoiModel poi;
  final double distanceMeters;
}

class _RecommendationsOverlay extends StatefulWidget {
  const _RecommendationsOverlay({
    required this.places,
    required this.hasUserPosition,
    required this.onRefreshLocation,
    required this.onPlaceTap,
  });

  final List<_RecommendedPlace> places;
  final bool hasUserPosition;
  final VoidCallback onRefreshLocation;
  final ValueChanged<PoiModel> onPlaceTap;

  @override
  State<_RecommendationsOverlay> createState() =>
      _RecommendationsOverlayState();
}

class _RecommendationsOverlayState extends State<_RecommendationsOverlay> {
  static const _compactSize = 0.12;
  static const _halfSize = 0.5;
  static const _fullSize = 0.92;

  late final DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
          controller: _sheetController,
          minChildSize: _compactSize,
          initialChildSize: _compactSize,
          maxChildSize: _fullSize,
          snap: true,
          snapSizes: const [_compactSize, _halfSize, _fullSize],
          snapAnimationDuration: const Duration(milliseconds: 180),
          builder: (context, scrollController) {
            return _SheetSurface(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _CompactTopSpacer(
                      controller: _sheetController,
                      compactSize: _compactSize,
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  _buildPlacesSliver(context),
                ],
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _CompactNearbyButton(
            controller: _sheetController,
            compactSize: _compactSize,
            onPressed: _expandToHalf,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(child: _SheetHandle()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended nearby',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh location',
                  onPressed: widget.onRefreshLocation,
                  icon: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesSliver(BuildContext context) {
    if (!widget.hasUserPosition) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _RecommendationsEmptyState(
          icon: Icons.location_searching,
          message: 'Tap the location button to find places near you.',
          actionLabel: 'Use my location',
          onActionPressed: widget.onRefreshLocation,
        ),
      );
    }

    if (widget.places.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _RecommendationsEmptyState(
          icon: Icons.explore_off,
          message: 'There are no saved places nearby yet.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      sliver: SliverList.builder(
        itemCount: widget.places.length,
        itemBuilder: (context, index) {
          final place = widget.places[index];
          final poi = place.poi;
          final type = PlaceTypeUi.fromType(poi.category);

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: type.color.withAlpha(
                AppConstants.poiSheetTintAlpha,
              ),
              child: Icon(type.icon, color: type.color, size: 20),
            ),
            title: Text(poi.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${type.label} • ${_formatDistance(place.distanceMeters)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onPlaceTap(poi),
          );
        },
      ),
    );
  }

  String get _subtitle {
    if (!widget.hasUserPosition) return 'Enable location to calculate distance';
    if (widget.places.isEmpty) return 'No places within 5 km yet';
    return 'Closest places within 5 km';
  }

  Future<void> _expandToHalf() async {
    await _sheetController.animateTo(
      _halfSize,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(kilometers < 10 ? 1 : 0)} km';
  }
}

class _CompactTopSpacer extends StatelessWidget {
  const _CompactTopSpacer({
    required this.controller,
    required this.compactSize,
  });

  static const _maxHeight = 76.0;

  final DraggableScrollableController controller;
  final double compactSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SizedBox(
          height: _maxHeight * _compactProgress(controller, compactSize),
        );
      },
    );
  }
}

class _CompactNearbyButton extends StatelessWidget {
  const _CompactNearbyButton({
    required this.controller,
    required this.compactSize,
    required this.onPressed,
  });

  final DraggableScrollableController controller;
  final double compactSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = _compactProgress(controller, compactSize);
        return IgnorePointer(
          ignoring: progress == 0,
          child: Opacity(
            opacity: progress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: _SheetHandle()),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: onPressed,
                      icon: const Icon(Icons.place_outlined),
                      label: const Text('Places nearby'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

double _compactProgress(
  DraggableScrollableController controller,
  double compactSize,
) {
  const hiddenAt = 0.2;
  final size = controller.isAttached ? controller.size : compactSize;
  final rawProgress = (hiddenAt - size) / (hiddenAt - compactSize);
  return rawProgress.clamp(0.0, 1.0);
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(
          AppConstants.sheetHandleAlpha,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _RecommendationsEmptyState extends StatelessWidget {
  const _RecommendationsEmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
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
