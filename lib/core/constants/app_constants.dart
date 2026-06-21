import 'package:latlong2/latlong.dart';

/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Default map center — Hangzhou, China.
  static const defaultMapCenter = LatLng(30.2741, 120.1551);

  /// Default zoom level.
  static const defaultZoom = 12.0;

  /// Zoom level when navigating to a specific place.
  static const placeZoom = 16.0;

  /// AMap deep link source application identifier.
  static const amapSourceApp = 'emap_hangzhou';

  /// AMap API key for tile access (Android/iOS platform).
  static const amapApiKey = 'dd8c7da64eb4197f3ea9a6bd78a95013';

  /// AMap API key for Web Service (search, geocoding).
  static const amapWebApiKey = '221a7ebad52852c52d73f48f41dc2a0e';
}
