import 'package:isar_community/isar.dart';

import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';

part 'isar_place_model.g.dart';

/// Isar-backed data model for [PlaceEntity].
@collection
class IsarPlaceModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late double latitude;
  late double longitude;
  late String title;
  late String comment;

  @Enumerated(EnumType.name)
  late PlaceType type;

  late DateTime createdAt;
}
