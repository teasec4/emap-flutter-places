import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/amap_search_result.dart';

/// Wraps AMap Input Tips API for location search.
///
/// https://restapi.amap.com/v3/assistant/inputtips
class AmapSearchService {
  AmapSearchService._();

  static const _baseUrl = 'https://restapi.amap.com/v3/assistant/inputtips';

  /// Searches for places matching [query]. Returns up to 10 suggestions.
  static Future<List<AmapSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'key': AppConstants.amapWebApiKey,
        'keywords': query.trim(),
        'city': 'hangzhou',
        'output': 'json',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != '1') return [];

      final tips = data['tips'] as List<dynamic>?;
      if (tips == null) return [];

      return tips
          .where(
            (t) =>
                t['location'] != null && (t['location'] as String).isNotEmpty,
          )
          .map((t) => AmapSearchResult.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
