import 'package:flutter/material.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/features/map/domain/entities/recommended_place.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/place_type_ui.dart';
import 'package:emap_hangzhou/features/map/presentation/widgets/sheet_widgets.dart';

class RecommendationsOverlay extends StatefulWidget {
  const RecommendationsOverlay({
    required this.places,
    required this.hasUserPosition,
    required this.onRefreshLocation,
    required this.onPlaceTap,
    super.key,
  });

  final List<RecommendedPlace> places;
  final bool hasUserPosition;
  final VoidCallback onRefreshLocation;
  final ValueChanged<PoiModel> onPlaceTap;

  @override
  State<RecommendationsOverlay> createState() => _RecommendationsOverlayState();
}

class _RecommendationsOverlayState extends State<RecommendationsOverlay> {
  static const _compactSize = 0.14;
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
            return SheetSurface(
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
          const Center(child: SheetHandle()),
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

  static const _maxHeight = 96.0;

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
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(child: SheetHandle()),
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
