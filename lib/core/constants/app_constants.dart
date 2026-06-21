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
}
