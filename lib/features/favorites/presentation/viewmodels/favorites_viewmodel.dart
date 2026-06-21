import 'package:flutter/material.dart';

import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/domain/repositories/place_repository.dart';

/// ViewModel for the Favorites screen.
///
/// Manages the list of saved places with delete capability.
/// Shares the same [PlaceRepository] as [MapViewModel].
class FavoritesViewModel extends ChangeNotifier {
  FavoritesViewModel({required PlaceRepository repository})
    : _repository = repository;

  final PlaceRepository _repository;

  List<PlaceEntity> _places = [];
  bool _isLoading = false;

  /// All saved places ordered by creation time (newest first).
  List<PlaceEntity> get places => List.unmodifiable(_places);

  /// Whether data is currently being loaded or deleted.
  bool get isLoading => _isLoading;

  /// Loads all places from the repository and notifies listeners.
  Future<void> loadPlaces() async {
    _isLoading = true;
    notifyListeners();

    _places = await _repository.getPlaces();

    _isLoading = false;
    notifyListeners();
  }

  /// Deletes a place by its business [id] and removes it from the list.
  Future<void> deletePlace(String id) async {
    await _repository.deletePlace(id);
    _places = _places.where((p) => p.id != id).toList();
    notifyListeners();
  }
}
