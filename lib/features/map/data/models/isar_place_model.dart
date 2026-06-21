import 'package:isar_community/isar.dart';

part 'isar_place_model.g.dart';

/// Isar-backed data model for [PlaceEntity].
///
/// Contains Isar-specific annotations. The repository maps between
/// this model and the domain [PlaceEntity] at the data/domain boundary.
@collection
class IsarPlaceModel {
  /// Auto-incremented internal Isar ID (not exposed outside the data layer).
  Id isarId = Isar.autoIncrement;

  /// Business identifier (UUID).
  @Index(unique: true)
  late String id;

  late double latitude;
  late double longitude;
  late String title;
  late String comment;
  late DateTime createdAt;
}
