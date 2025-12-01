import 'dart:convert';

class FitnessSpot {
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final double? rating;
  final String placeId;
  final int ratingCount;
  final String? website;
  final String? phoneNumber;
  final List<String> types;
  final double? distanceKm;
  final String? description;

  FitnessSpot({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.rating,
    required this.placeId,
    required this.ratingCount,
    this.website,
    this.phoneNumber,
    required this.types,
    this.distanceKm,
    this.description,
  });

  factory FitnessSpot.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return FitnessSpot(
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      latitude: toDouble(json['latitude'] ?? json['lat']) ?? 0.0,
      longitude: toDouble(json['longitude'] ?? json['lng'] ?? json['lon']) ?? 0.0,
      address: json['address']?.toString() ?? json['alamat']?.toString() ?? '',
      rating: toDouble(json['rating']),
      placeId: json['place_id']?.toString() ?? json['id']?.toString() ?? '',
      ratingCount: json['rating_count'] is int ? json['rating_count'] : 0,
      website: json['website']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      types: json['types'] is List ? List<String>.from(json['types']) : [],
      distanceKm: toDouble(json['distance'] ?? json['distance_km'] ?? json['distanceKm']),
      description: json['description']?.toString() ?? json['detail']?.toString() ?? json['deskripsi']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'rating': rating,
      'place_id': placeId,
      'rating_count': ratingCount,
      'website': website,
      'phone_number': phoneNumber,
      'types': types,
      'distance_km': distanceKm,
      'description': description,
    };
  }
}
