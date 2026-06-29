import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:emap_hangzhou/core/services/poi_model.dart';
import 'package:emap_hangzhou/core/services/poi_service.dart';

class MapViewModel extends ChangeNotifier {
  List<PoiModel> _pois = [];
  bool _isLoading = false;
  String? _error;

  List<PoiModel> get pois => List.unmodifiable(_pois);
  bool get isLoading => _isLoading;
  String? get error => _error;

  LatLng? initialPosition;

  Future<void> loadPois() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final (pois, err) = await PoiService.fetchPois();
    _pois = pois;
    _error = err;
    _isLoading = false;
    notifyListeners();
  }
}
