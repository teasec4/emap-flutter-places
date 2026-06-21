import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/data/models/isar_place_model.dart';

/// Pure data-layer DTO. Handles mapping between Isar and domain layers.
///
/// Keeps Isar annotations decoupled from domain entities.
class PlaceModel {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String comment;
  final DateTime createdAt;

  const PlaceModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.comment,
    required this.createdAt,
  });

  /// Creates a [PlaceModel] from an Isar model.
  factory PlaceModel.fromIsar(IsarPlaceModel model) => PlaceModel(
    id: model.id,
    latitude: model.latitude,
    longitude: model.longitude,
    title: model.title,
    comment: model.comment,
    createdAt: model.createdAt,
  );

  /// Converts to an Isar model (for writes).
  IsarPlaceModel toIsar() => IsarPlaceModel()
    ..id = id
    ..latitude = latitude
    ..longitude = longitude
    ..title = title
    ..comment = comment
    ..createdAt = createdAt;

  /// Converts to a domain entity.
  PlaceEntity toEntity() => PlaceEntity(
    id: id,
    latitude: latitude,
    longitude: longitude,
    title: title,
    comment: comment,
    createdAt: createdAt,
  );

  /// Creates a [PlaceModel] from a domain entity.
  factory PlaceModel.fromEntity(PlaceEntity entity) => PlaceModel(
    id: entity.id,
    latitude: entity.latitude,
    longitude: entity.longitude,
    title: entity.title,
    comment: entity.comment,
    createdAt: entity.createdAt,
  );
}
