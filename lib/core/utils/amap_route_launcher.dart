import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';

/// AMap deep-link query parameter names. Only the destination is provided;
/// AMap fills the user's current position from GPS.
class _AmapParam {
  _AmapParam._();

  static const sourceApplication = 'sourceApplication';
  static const dlat = 'dlat';
  static const dlon = 'dlon';
  static const dname = 'dname';
  static const dev = 'dev';
  static const t = 't';
  static const zero = '0';
}

/// Builds and launches an AMap (高德地图) deep link for route navigation.
class AmapRouteLauncher {
  AmapRouteLauncher._();

  /// Opens AMap with a route to [latitude], [longitude].
  /// [name], when non-null and non-empty, labels the destination pin.
  ///
  /// Returns `true` if AMap was launched, `false` if it is not installed.
  static Future<bool> launch({
    required double latitude,
    required double longitude,
    String? name,
  }) async {
    final uri = _buildUri(latitude: latitude, longitude: longitude, name: name);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  static Uri _buildUri({
    required double latitude,
    required double longitude,
    String? name,
  }) {
    // `dev=0` lets AMap auto-detect coordinate system from device location;
    // `t=0` requests car-routing mode (driving, default).
    final params = <String, String>{
      _AmapParam.dlat: latitude.toString(),
      _AmapParam.dlon: longitude.toString(),
      _AmapParam.dev: _AmapParam.zero,
      _AmapParam.t: _AmapParam.zero,
      if (name != null && name.isNotEmpty) _AmapParam.dname: name,
    };

    if (Platform.isIOS) {
      return Uri(
        scheme: 'iosamap',
        host: 'path',
        queryParameters: {
          _AmapParam.sourceApplication: AppConstants.amapSourceApp,
          ...params,
        },
      );
    }

    return Uri(
      scheme: 'amapuri',
      host: 'route',
      path: 'plan',
      queryParameters: params,
    );
  }
}
