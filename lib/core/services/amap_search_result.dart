/// A single search result from AMap Input Tips API.
class AmapSearchResult {
  final String name;
  final String district;
  final double latitude;
  final double longitude;

  const AmapSearchResult({
    required this.name,
    required this.district,
    required this.latitude,
    required this.longitude,
  });

  factory AmapSearchResult.fromJson(Map<String, dynamic> json) {
    final loc = (json['location'] as String).split(',');
    return AmapSearchResult(
      name: json['name'] as String,
      district: (json['district'] as String?) ?? '',
      latitude: double.parse(loc[1]),
      longitude: double.parse(loc[0]),
    );
  }
}
