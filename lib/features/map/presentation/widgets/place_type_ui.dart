import 'package:flutter/material.dart';

import 'package:emap_hangzhou/features/map/domain/entities/place_type.dart';

/// Flutter-specific UI helpers for [PlaceType].
extension PlaceTypeUi on PlaceType {
  IconData get icon {
    switch (this) {
      case PlaceType.restaurant:
        return Icons.restaurant;
      case PlaceType.exhibition:
        return Icons.theater_comedy;
      case PlaceType.museum:
        return Icons.museum;
      case PlaceType.other:
        return Icons.place;
    }
  }

  Color get color {
    switch (this) {
      case PlaceType.restaurant:
        return Colors.orange;
      case PlaceType.exhibition:
        return Colors.purple;
      case PlaceType.museum:
        return Colors.teal;
      case PlaceType.other:
        return Colors.red;
    }
  }

  String get label {
    switch (this) {
      case PlaceType.restaurant:
        return 'Restaurant';
      case PlaceType.exhibition:
        return 'Exhibition';
      case PlaceType.museum:
        return 'Museum';
      case PlaceType.other:
        return 'Other';
    }
  }
}
