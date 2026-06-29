import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';

class PoiService {
  PoiService._();

  static Future<(List<PoiModel>, String?)> fetchPois() async {
    final url = '${AppConstants.apiBaseUrl}${AppConstants.apiPoisPath}';
    final uri = Uri.parse(url);

    try {
      final response = await http.get(uri).timeout(AppConstants.networkTimeout);

      if (response.statusCode != 200) {
        return (<PoiModel>[], 'HTTP ${response.statusCode}\n$url');
      }

      final list = json.decode(response.body) as List<dynamic>;
      return (
        list.map((j) => PoiModel.fromJson(j as Map<String, dynamic>)).toList(),
        null,
      );
    } catch (e) {
      return (<PoiModel>[], '$url\n${e.toString().split('\n').first}');
    }
  }
}
