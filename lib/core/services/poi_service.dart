import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import 'package:emap_hangzhou/core/services/poi_model.dart';

/// Fetches POIs from the backend API.
class PoiService {
  static const _baseUrl = 'https://content.nalichi.fun';

  /// Returns (pois, errorMessage). One of them is always non-null/empty.
  static Future<(List<PoiModel>, String?)> fetchPois() async {
    final uri = Uri.parse('$_baseUrl/api/public/poi');
    try {
      dev.log('POI: GET $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      dev.log('POI: status=${response.statusCode}');

      if (response.statusCode != 200) {
        final msg = 'Server error: ${response.statusCode}';
        dev.log('POI: $msg');
        return (<PoiModel>[], msg);
      }

      final list = json.decode(response.body) as List<dynamic>;
      dev.log('POI: got ${list.length} items');
      return (
        list.map((j) => PoiModel.fromJson(j as Map<String, dynamic>)).toList(),
        null,
      );
    } catch (e) {
      final msg = 'Connection failed: $e';
      dev.log('POI: $msg');
      return (<PoiModel>[], msg);
    }
  }
}
