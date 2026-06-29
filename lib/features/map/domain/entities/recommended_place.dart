import 'package:emap_hangzhou/core/services/poi_model.dart';

class RecommendedPlace {
  const RecommendedPlace({required this.poi, required this.distanceMeters});

  final PoiModel poi;
  final double distanceMeters;
}
