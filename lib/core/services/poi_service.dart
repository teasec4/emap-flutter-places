import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:emap_hangzhou/core/services/poi_model.dart';

/// Fetches POIs from the backend API at content.nalichi.fun.
class PoiService {
  static const _baseUrl = 'https://content.nalichi.fun';

  /// Returns all published POIs (public endpoint, no auth).
  static Future<List<PoiModel>> fetchPois() async {
    final uri = Uri.parse('$_baseUrl/api/public/poi');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final list = json.decode(response.body) as List<dynamic>;
      return list
          .map((j) => PoiModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
