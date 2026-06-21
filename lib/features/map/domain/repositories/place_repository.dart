import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';

/// Abstract contract for place persistence.
///
/// Defined in the domain layer — the data layer provides the concrete
/// [PlaceRepositoryImpl]. Both the Map and Favorites features depend
/// on this interface (Dependency Inversion Principle).
abstract class PlaceRepository {
  /// Persists a new place or updates an existing one.
  Future<void> savePlace(PlaceEntity place);

  /// Returns all saved places ordered by creation date (newest first).
  Future<List<PlaceEntity>> getPlaces();

  /// Deletes a place by its business [id].
  Future<void> deletePlace(String id);
}
