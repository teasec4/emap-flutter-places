import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:emap_hangzhou/features/map/data/models/isar_place_model.dart';

/// Initializes and exposes a singleton Isar instance.
///
/// Call [init] once before using the database.
class IsarService {
  static Isar? _isar;

  static Isar get instance {
    if (_isar == null) {
      throw StateError('IsarService not initialized. Call init() first.');
    }
    return _isar!;
  }

  static Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      <CollectionSchema<dynamic>>[IsarPlaceModelSchema],
      directory: dir.path,
      name: 'emap_hangzhou',
    );
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
