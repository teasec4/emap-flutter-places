import 'package:latlong2/latlong.dart';

/// App-wide constants. No business logic, no secrets that are never used.
class AppConstants {
  AppConstants._();

  // --- Map -------------------------------------------------------------

  /// Default map center — Hangzhou, China.
  static const defaultMapCenter = LatLng(30.2741, 120.1551);

  /// Default zoom for the initial map view.
  static const defaultZoom = 12.0;

  /// Upper bound accepted by tile providers.
  static const tileMaxZoom = 19.0;

  // --- AMap tile provider ----------------------------------------------

  /// AMap raster tile URL template. `style=8` = old/vector-like raster style.
  static const amapTileUrlTemplate =
      'https://webrd0{s}.is.autonavi.com/appmaptile'
      '?lang=zh_cn&size=1&scale=1&style=8'
      '&x={x}&y={y}&z={z}';

  /// Subdomains AMap rotates through to spread load.
  static const amapTileSubdomains = ['1', '2', '3', '4'];

  /// Native max zoom AMap raster tiles support.
  static const amapTileMaxNativeZoom = 18;

  /// User agent the tile provider advertises.
  ///
  /// Keep this in sync with the Android applicationId until flavors are added.
  static const tileUserAgentPackageName = 'com.example.emap_hangzhou';

  // --- AMap deep link --------------------------------------------------

  /// Source app identifier embedded in AMap deep links.
  static const amapSourceApp = 'emap_hangzhou';

  // --- Server ----------------------------------------------------------

  /// Public POI API base URL.
  static const apiBaseUrl = 'https://content.nalichi.fun';
  static const apiPoisPath = '/api/public/pois';

  // --- Timings ---------------------------------------------------------

  /// Server request timeout.
  static const networkTimeout = Duration(seconds: 10);

  /// Location request timeout for startup and manual refresh.
  static const locationTimeout = Duration(seconds: 5);

  // --- Recommendations -------------------------------------------------

  /// Radius used for the initial "near you" recommendations overlay.
  static const nearbyPlacesRadiusMeters = 5000.0;

  /// Zoom used when a recommendation is selected.
  static const selectedPlaceZoom = 15.0;

  // --- Marker visuals --------------------------------------------------

  /// Size of the tappable POI marker (logical px).
  static const poiMarkerSize = 44.0;

  /// Size of the user-location dot (logical px).
  static const userMarkerSize = 20.0;

  /// Border width for the POI marker ring.
  static const poiMarkerBorderWidth = 2.0;

  /// Border width for the user-location ring.
  static const userMarkerBorderWidth = 3.0;

  /// Fill opacity for the POI marker background.
  static const poiMarkerFillAlpha = 40; // out of 255

  /// Tint opacity for the POI marker container in the sheet.
  static const poiSheetTintAlpha = 30;

  /// Tint opacity for the place-type chip background.
  static const poiSheetChipAlpha = 25;

  /// Opacity for the drag-handle bar on the POI sheet.
  static const sheetHandleAlpha = 50;
}
