/// Matches server JSON: id, name, category, lat, lng, comment, createdAt, updatedAt.
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
    String safeString(dynamic value) => (value ?? '').toString().trim();
    double safeDouble(dynamic value) => value is num ? value.toDouble() : 0;
    DateTime safeDate(dynamic value) {
      final date = DateTime.tryParse(safeString(value));
      return date ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    final lat = safeDouble(json['lat']);
    final lng = safeDouble(json['lng']);
    final id = safeString(json['id']);

    return PoiModel(
      id: id.isNotEmpty ? id : '$lat,$lng:${safeString(json['name'])}',
      name: safeString(json['name']),
      category: safeString(json['category'] ?? json['type']),
      lat: lat,
      lng: lng,
      comment: json['comment']?.toString(),
      createdAt: safeDate(json['createdAt']),
      updatedAt: safeDate(json['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PoiModel &&
            other.id == id &&
            other.name == name &&
            other.category == category &&
            other.lat == lat &&
            other.lng == lng &&
            other.comment == comment &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, lat, lng, comment, createdAt, updatedAt);
}
