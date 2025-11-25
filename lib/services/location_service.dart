import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/location_point.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class LocationService {
  const LocationService();

  Future<List<LocationPoint>> fetchLocations(CookieRequest request) async {
    final url = '$djangoBaseUrl$homeLocationsEndpoint';
    dynamic raw;
    try {
      raw = await request.get(url);
    } catch (e) {
      throw FormatException(
        'Response bukan JSON. Pastikan $homeLocationsEndpoint mengembalikan JSON. URL: $url Error: $e',
      );
    }

    if (raw is String && raw.trim().startsWith('<')) {
      throw const FormatException(
        'Response HTML terdeteksi (mungkin endpoint salah atau belum login). Pastikan endpoint mengembalikan JSON.',
      );
    }

    List<dynamic> dataList = [];
    if (raw is List) {
      dataList = raw;
    } else if (raw is Map && raw['data'] is List) {
      dataList = raw['data'] as List;
    } else if (raw is Map && raw['results'] is List) {
      dataList = raw['results'] as List;
    }

    return dataList
        .whereType<Map<String, dynamic>>()
        .map(LocationPoint.fromJson)
        .toList();
  }
}
