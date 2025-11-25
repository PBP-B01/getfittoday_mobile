class LocationPoint {
  final int? id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? category;

  const LocationPoint({
    this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.category,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
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
    );
  }
}
