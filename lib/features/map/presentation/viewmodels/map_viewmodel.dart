import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/services/poi_service.dart';

class MapViewModel extends ChangeNotifier {
  List<PoiModel> _pois = [];
  bool _isLoading = false;

  List<PoiModel> get pois => List.unmodifiable(_pois);
  bool get isLoading => _isLoading;

  /// Set by splash screen after getting GPS fix. Null if unavailable.
  LatLng? initialPosition;

  Future<void> loadPois() async {
    _isLoading = true;
    notifyListeners();
    _pois = await PoiService.fetchPois();
    _isLoading = false;
    notifyListeners();
  }
}
