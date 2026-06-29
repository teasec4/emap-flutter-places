import 'package:latlong2/latlong.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/utils/coordinate_utils.dart';
import 'package:emap_hangzhou/features/map/domain/entities/recommended_place.dart';

class PlaceRecommendationService {
  PlaceRecommendationService._();

  static List<RecommendedPlace> nearbyPlaces({
    required LatLng? userPosition,
    required List<PoiModel> pois,
    double radiusMeters = AppConstants.nearbyPlacesRadiusMeters,
  }) {
    if (userPosition == null) return const [];

    const distance = Distance();
    final places = pois
        .map((poi) {
          final meters = distance.as(
            LengthUnit.Meter,
            userPosition,
            CoordinateUtils.gcj02ToWgs84(LatLng(poi.lat, poi.lng)),
          );
          return RecommendedPlace(poi: poi, distanceMeters: meters);
        })
        .where((place) => place.distanceMeters <= radiusMeters)
        .toList(growable: false);

    return [...places]..sort(
      (left, right) => left.distanceMeters.compareTo(right.distanceMeters),
    );
  }
}
