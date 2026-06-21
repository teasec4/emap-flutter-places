import 'package:latlong2/latlong.dart';

/// Core domain entity representing a saved place/bookmark.
///
/// Owned by the domain layer. No framework dependencies.
/// The data layer maps [PlaceModel] ↔ [PlaceEntity] at the repository boundary.
class PlaceEntity {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String comment;
  final DateTime createdAt;

  const PlaceEntity({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.comment,
    required this.createdAt,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}
