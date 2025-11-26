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
    } else if (raw is Map) {
      final candidateKeys = [
        'spots',
        'locations',
        'data',
        'results',
        'items',
      ];
      for (final key in candidateKeys) {
        final value = raw[key];
        if (value is List) {
          dataList = value;
          break;
        }
      }
      // Some APIs wrap the list in a single unnamed key.
      if (dataList.isEmpty && raw.length == 1) {
        final onlyValue = raw.values.first;
        if (onlyValue is List) {
          dataList = onlyValue;
        }
      }
    }

    return dataList
        .whereType<Map<String, dynamic>>()
        .map(LocationPoint.fromJson)
        .toList();
  }
}
