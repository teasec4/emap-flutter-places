/// Matches server JSON: id, name, category, lat, lng, comment, createdAt, updatedAt
class PoiModel {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PoiModel({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic v) => (v ?? '').toString();
    double safeDouble(dynamic v) => ((v ?? 0) as num).toDouble();
    DateTime safeDate(dynamic v) {
      final s = safeString(v);
      return s.isNotEmpty ? DateTime.parse(s) : DateTime.now();
    }

    return PoiModel(
      id: safeString(json['id']),
      name: safeString(json['name']),
      category: safeString(json['category']),
      lat: safeDouble(json['lat']),
      lng: safeDouble(json['lng']),
      comment: json['comment']?.toString(),
      createdAt: safeDate(json['createdAt']),
      updatedAt: safeDate(json['updatedAt']),
    );
  }
}
