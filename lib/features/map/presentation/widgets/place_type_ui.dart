import 'package:flutter/material.dart';

import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';

/// Flutter-specific UI helpers for [PlaceType].
extension PlaceTypeUi on PlaceType {
  IconData get icon {
    switch (this) {
      case PlaceType.food:
        return Icons.restaurant;
      case PlaceType.coffee:
        return Icons.coffee;
      case PlaceType.sport:
        return Icons.fitness_center;
      case PlaceType.relax:
        return Icons.spa;
      case PlaceType.shopping:
        return Icons.shopping_bag;
      case PlaceType.culture:
        return Icons.museum;
      case PlaceType.nature:
        return Icons.park;
      case PlaceType.other:
        return Icons.place;
    }
  }

  Color get color {
    switch (this) {
      case PlaceType.food:
        return Colors.orange;
      case PlaceType.coffee:
        return Colors.brown;
      case PlaceType.sport:
        return Colors.green;
      case PlaceType.relax:
        return Colors.purple;
      case PlaceType.shopping:
        return Colors.pink;
      case PlaceType.culture:
        return Colors.teal;
      case PlaceType.nature:
        return Colors.lightGreen;
      case PlaceType.other:
        return Colors.red;
    }
  }

  String get label {
    switch (this) {
      case PlaceType.food:
        return 'Food';
      case PlaceType.coffee:
        return 'Coffee';
      case PlaceType.sport:
        return 'Sport';
      case PlaceType.relax:
        return 'Relax';
      case PlaceType.shopping:
        return 'Shopping';
      case PlaceType.culture:
        return 'Culture';
      case PlaceType.nature:
        return 'Nature';
      case PlaceType.other:
        return 'Other';
    }
  }

  /// Parse from server `type` string (e.g. "cafe", "food").
  ///
  /// Falls back to [PlaceType.other] for unknown values. A few server-side
  /// aliases (e.g. "cafe") are mapped onto the canonical enum values so the
  /// marker icon stays meaningful.
  static PlaceType fromType(String type) {
    const aliases = <String, PlaceType>{
      'cafe': PlaceType.coffee,
      'bar': PlaceType.coffee,
      'restaurant': PlaceType.food,
      'viewpoint': PlaceType.culture,
      'museum': PlaceType.culture,
      'park': PlaceType.nature,
    };
    final mapped =
        aliases[type] ??
        PlaceType.values.firstWhere(
          (t) => t.name == type,
          orElse: () => PlaceType.other,
        );
    return mapped;
  }
}
