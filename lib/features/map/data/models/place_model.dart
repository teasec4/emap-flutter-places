import 'package:emap_hangzhou/features/map/domain/entities/place_entity.dart';
import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';
import 'package:emap_hangzhou/features/map/data/models/isar_place_model.dart';

/// Pure data-layer DTO. Handles mapping between Isar and domain layers.
class PlaceModel {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String comment;
  final PlaceType type;
  final DateTime createdAt;

  const PlaceModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.comment,
    this.type = PlaceType.other,
    required this.createdAt,
  });

  factory PlaceModel.fromIsar(IsarPlaceModel model) => PlaceModel(
    id: model.id,
    latitude: model.latitude,
    longitude: model.longitude,
    title: model.title,
    comment: model.comment,
    type: model.type,
    createdAt: model.createdAt,
  );

  IsarPlaceModel toIsar() => IsarPlaceModel()
    ..id = id
    ..latitude = latitude
    ..longitude = longitude
    ..title = title
    ..comment = comment
    ..type = type
    ..createdAt = createdAt;

  PlaceEntity toEntity() => PlaceEntity(
    id: id,
    latitude: latitude,
    longitude: longitude,
    title: title,
    comment: comment,
    type: type,
    createdAt: createdAt,
  );

  factory PlaceModel.fromEntity(PlaceEntity entity) => PlaceModel(
    id: entity.id,
    latitude: entity.latitude,
    longitude: entity.longitude,
    title: entity.title,
    comment: entity.comment,
    type: entity.type,
    createdAt: entity.createdAt,
  );
}
