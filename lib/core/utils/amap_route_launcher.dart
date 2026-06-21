import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';

/// Builds and launches an AMap (高德地图) deep link for route navigation.
///
/// The user's current location is left empty so AMap uses GPS to fill it.
/// Only the destination coordinates are provided.
class AmapRouteLauncher {
  /// Opens AMap with a route to the given destination.
  ///
  /// [latitude] and [longitude] are the destination coordinates.
  /// [name] is an optional label for the destination.
  ///
  /// Returns `true` if AMap was launched, `false` if it is not installed.
  static Future<bool> launch({
    required double latitude,
    required double longitude,
    String? name,
  }) async {
    final uri = _buildUri(latitude: latitude, longitude: longitude, name: name);

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }

    return false;
  }

  static Uri _buildUri({
    required double latitude,
    required double longitude,
    String? name,
  }) {
    if (Platform.isIOS) {
      return Uri(
        scheme: 'iosamap',
        host: 'path',
        queryParameters: {
          'sourceApplication': AppConstants.amapSourceApp,
          'dlat': latitude.toString(),
          'dlon': longitude.toString(),
          if (name != null && name.isNotEmpty) 'dname': name,
          'dev': '0',
          't': '0',
        },
      );
    }

    // Android / fallback
    return Uri(
      scheme: 'amapuri',
      host: 'route',
      path: 'plan',
      queryParameters: {
        'dlat': latitude.toString(),
        'dlon': longitude.toString(),
        if (name != null && name.isNotEmpty) 'dname': name,
        'dev': '0',
        't': '0',
      },
    );
  }
}
