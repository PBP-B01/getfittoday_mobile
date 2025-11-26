class LocationPoint {
  final int? id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? category;
  final double? distanceKm;

  const LocationPoint({
    this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.category,
    this.distanceKm,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    double? _distanceFrom(dynamic v) {
      return _toDouble(v ?? json['distance_km'] ?? json['distanceKm']);
    }

    return LocationPoint(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: json['name']?.toString() ??
          json['title']?.toString() ??
          'Lokasi tanpa nama',
      address: json['address']?.toString() ?? json['alamat']?.toString(),
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      description: json['description']?.toString() ??
          json['detail']?.toString() ??
          json['deskripsi']?.toString(),
      category: json['category']?.toString() ?? json['kategori']?.toString(),
      distanceKm: _distanceFrom(json['distance']),
    );
  }
}
