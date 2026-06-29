import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Converts between WGS-84 (GPS, global standard) and GCJ-02 (Chinese offset).
///
/// AMap tiles use GCJ-02. Device GPS is WGS-84.
/// Convert GPS coordinates before drawing them on AMap tiles; do not convert
/// coordinates that already come from AMap/GCJ-02 sources.
class CoordinateUtils {
  CoordinateUtils._();

  static const double _pi = 3.141592653589793;
  static const double _a = 6378245.0;
  static const double _ee = 0.00669342162296594323;

  /// Convert WGS-84 → GCJ-02 (for displaying on AMap tiles).
  static LatLng wgs84ToGcj02(LatLng wgs) {
    if (_outOfChina(wgs)) return wgs;

    var lat = wgs.latitude;
    var lng = wgs.longitude;

    var dLat = _transformLat(lng - 105.0, lat - 35.0);
    var dLng = _transformLng(lng - 105.0, lat - 35.0);
    var radLat = lat / 180.0 * _pi;
    var magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    var sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * _pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * _pi);

    return LatLng(lat + dLat, lng + dLng);
  }

  /// Convert GCJ-02 → WGS-84 (for saving GPS-correct coordinates).
  static LatLng gcj02ToWgs84(LatLng gcj) {
    if (_outOfChina(gcj)) return gcj;

    var lat = gcj.latitude;
    var lng = gcj.longitude;

    var dLat = _transformLat(lng - 105.0, lat - 35.0);
    var dLng = _transformLng(lng - 105.0, lat - 35.0);
    var radLat = lat / 180.0 * _pi;
    var magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    var sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * _pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * _pi);

    return LatLng(lat - dLat, lng - dLng);
  }

  static bool _outOfChina(LatLng coord) {
    return coord.longitude < 72.004 ||
        coord.longitude > 137.8347 ||
        coord.latitude < 0.8293 ||
        coord.latitude > 55.8271;
  }

  static double _transformLat(double x, double y) {
    var ret =
        -100.0 +
        2.0 * x +
        3.0 * y +
        0.2 * y * y +
        0.1 * x * y +
        0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * _pi) + 20.0 * sin(2.0 * x * _pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * _pi) + 40.0 * sin(y / 3.0 * _pi)) * 2.0 / 3.0;
    ret +=
        (160.0 * sin(y / 12.0 * _pi) + 320.0 * sin(y * _pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLng(double x, double y) {
    var ret =
        300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * _pi) + 20.0 * sin(2.0 * x * _pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * _pi) + 40.0 * sin(x / 3.0 * _pi)) * 2.0 / 3.0;
    ret +=
        (150.0 * sin(x / 12.0 * _pi) + 300.0 * sin(x / 30.0 * _pi)) * 2.0 / 3.0;
    return ret;
  }
}
