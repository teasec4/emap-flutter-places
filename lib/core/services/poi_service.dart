import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';

class PoiService {
  PoiService._();

  static Future<(List<PoiModel>, String?)> fetchPois() async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}${AppConstants.apiPoisPath}',
    );

    try {
      final response = await http.get(uri).timeout(AppConstants.networkTimeout);
      if (response.statusCode != 200) {
        log(
          'Failed to load POIs: HTTP ${response.statusCode}',
          name: 'PoiService',
        );
        return (<PoiModel>[], 'HTTP ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! List<dynamic>) {
        return (<PoiModel>[], 'Invalid POI response');
      }

      final pois = decoded
          .whereType<Map<String, dynamic>>()
          .map(PoiModel.fromJson)
          .toList(growable: false);
      return (pois, null);
    } catch (error, stackTrace) {
      log(
        'Failed to load POIs',
        name: 'PoiService',
        error: error,
        stackTrace: stackTrace,
      );
      return (<PoiModel>[], error.toString());
    }
  }
}
