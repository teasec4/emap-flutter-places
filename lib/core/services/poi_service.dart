import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';

/// Fetches POIs from the public backend API.
class PoiService {
  PoiService._();

  /// Returns `(pois, errorMessage)`. Exactly one of them is "useful":
  /// either a populated list with `errorMessage == null`, or an empty list
  /// with a non-null message describing what went wrong.
  static Future<(List<PoiModel>, String?)> fetchPois() async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}${AppConstants.apiPoisPath}',
    );
    try {
      final response = await http.get(uri).timeout(AppConstants.networkTimeout);

      if (response.statusCode != 200) {
        return (<PoiModel>[], 'Server error: ${response.statusCode}');
      }

      final list = json.decode(response.body) as List<dynamic>;
      return (
        list.map((j) => PoiModel.fromJson(j as Map<String, dynamic>)).toList(),
        null,
      );
    } catch (e) {
      return (<PoiModel>[], 'Connection failed: $e');
    }
  }
}
