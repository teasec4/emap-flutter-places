import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/services/poi_model.dart';

class PoiService {
  PoiService._();

  static Future<(List<PoiModel>, String?)> fetchPois() async {
    final url = '${AppConstants.apiBaseUrl}${AppConstants.apiPoisPath}';
    final uri = Uri.parse(url);
    print('[POI] GET $url');

    try {
      final response = await http.get(uri).timeout(AppConstants.networkTimeout);
      print('[POI] status=${response.statusCode}');

      if (response.statusCode != 200) {
        print('[POI] BODY=${response.body}');
        return (<PoiModel>[], 'HTTP ${response.statusCode}');
      }

      final list = json.decode(response.body) as List<dynamic>;
      print('[POI] loaded ${list.length} items');
      return (
        list.map((j) => PoiModel.fromJson(j as Map<String, dynamic>)).toList(),
        null,
      );
    } catch (e, st) {
      print('[POI] FAIL $e');
      print('[POI] STACK $st');
      return (<PoiModel>[], '$e');
    }
  }
}
