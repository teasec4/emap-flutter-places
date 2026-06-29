/// Matches server-side Poi model (Go struct) at content.nalichi.fun
class PoiModel {
  final String id;
  final String name;
  final String category;
  final String? subcategory;
  final double lat;
  final double lng;
  final String? city;
  final String? sourceId;
  final String status;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PoiModel({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    required this.lat,
    required this.lng,
    this.city,
    this.sourceId,
    required this.status,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      city: json['city'] as String?,
      sourceId: json['sourceId'] as String?,
      status: json['status'] as String,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
