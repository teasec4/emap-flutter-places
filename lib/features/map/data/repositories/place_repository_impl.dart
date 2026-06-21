import 'package:isar_community/isar.dart';

import 'package:emap_hangzhou/core/services/isar_service.dart';
import 'package:emap_hangzhou/features/map/data/models/isar_place_model.dart';
import 'package:emap_hangzhou/features/map/data/models/place_model.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/domain/repositories/place_repository.dart';

/// Concrete implementation of [PlaceRepository] backed by Isar.
///
/// Maps between [PlaceEntity] (domain) and [IsarPlaceModel] (data) via
/// [PlaceModel] as the DTO layer.
class PlaceRepositoryImpl implements PlaceRepository {
  PlaceRepositoryImpl()
    : _isar = IsarService.instance,
      _places = IsarService.instance.isarPlaceModels;

  final Isar _isar;
  final IsarCollection<IsarPlaceModel> _places;

  @override
  Future<void> savePlace(PlaceEntity place) async {
    final model = PlaceModel.fromEntity(place).toIsar();
    await _isar.writeTxn(() async {
      await _places.put(model);
    });
  }

  @override
  Future<List<PlaceEntity>> getPlaces() async {
    final models = await _places.where().findAll();
    // Sort newest first in memory — sufficient for an MVP.
    models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return models.map((m) => PlaceModel.fromIsar(m).toEntity()).toList();
  }

  @override
  Future<void> deletePlace(String id) async {
    await _isar.writeTxn(() async {
      await _places.deleteById(id);
    });
  }
}
