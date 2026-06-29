import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/services/poi_service.dart';

class MapViewModel extends ChangeNotifier {
  List<PoiModel> _pois = const [];
  LatLng? _userPosition;
  String? _error;
  bool _isReady = false;
  bool _isLoading = false;
  int _initGeneration = 0;

  List<PoiModel> get pois => _pois;
  LatLng? get userPosition => _userPosition;
  String? get error => _error;
  bool get isReady => _isReady;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    final generation = ++_initGeneration;

    _isReady = false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final (pois, error) = await PoiService.fetchPois();
    if (generation != _initGeneration) return;

    _pois = List.unmodifiable(pois);
    _error = error;

    if (error == null) {
      await _tryGetLocation(notify: false);
      if (generation != _initGeneration) return;
      _isReady = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> refreshLocation() => _tryGetLocation();

  Future<bool> _tryGetLocation({bool notify = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: AppConstants.locationTimeout,
        ),
      );
      final nextPosition = LatLng(position.latitude, position.longitude);

      if (_userPosition == nextPosition) return true;
      _userPosition = nextPosition;
      if (notify) notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
