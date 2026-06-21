import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';
import 'package:emap_hangzhou/features/map/domain/repositories/place_repository.dart';

/// ViewModel for the Map screen.
///
/// Manages marker state and delegates persistence to [PlaceRepository].
/// Widgets observe [places] and call methods on this ViewModel — they
/// never contain business logic themselves.
class MapViewModel extends ChangeNotifier {
  MapViewModel({required PlaceRepository repository})
    : _repository = repository;

  final PlaceRepository _repository;
  final _uuid = const Uuid();

  List<PlaceEntity> _places = [];
  bool _isLoading = false;

  /// When non-null, the map should animate to these coordinates.
  /// Reset after consumption by the map widget.
  LatLng? _navigateTarget;

  /// All saved places displayed as markers on the map.
  List<PlaceEntity> get places => List.unmodifiable(_places);

  /// Whether data is currently being loaded or saved.
  bool get isLoading => _isLoading;

  /// The coordinates the map should animate to, then reset.
  LatLng? consumeNavigateTarget() {
    final target = _navigateTarget;
    _navigateTarget = null;
    return target;
  }

  /// Requests the map to center on the given coordinates.
  void navigateToPlace({required double latitude, required double longitude}) {
    _navigateTarget = LatLng(latitude, longitude);
    notifyListeners();
  }

  /// Loads all places from the repository and notifies listeners.
  Future<void> loadPlaces() async {
    _isLoading = true;
    notifyListeners();

    _places = await _repository.getPlaces();

    _isLoading = false;
    notifyListeners();
  }

  /// Persists a new place at the given coordinates.
  Future<void> savePlace({
    required double latitude,
    required double longitude,
    required String title,
    required String comment,
    PlaceType type = PlaceType.other,
  }) async {
    final place = PlaceEntity(
      id: _uuid.v4(),
      latitude: latitude,
      longitude: longitude,
      title: title,
      comment: comment,
      type: type,
      createdAt: DateTime.now(),
    );

    await _repository.savePlace(place);
    _places = [place, ..._places];
    notifyListeners();
  }
}
