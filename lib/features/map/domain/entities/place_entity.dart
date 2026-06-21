import 'package:latlong2/latlong.dart';

import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';

/// Core domain entity representing a saved place/bookmark.
class PlaceEntity {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String comment;
  final PlaceType type;
  final DateTime createdAt;

  const PlaceEntity({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.comment,
    this.type = PlaceType.other,
    required this.createdAt,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}
