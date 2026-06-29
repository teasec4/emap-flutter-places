/// Matches server-side Poi model (Go struct) at content.nalichi.fun
class PoiModel {
  final String id;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PoiModel({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
