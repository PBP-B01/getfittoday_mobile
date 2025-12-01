
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/fitness_spot.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class FitnessSpotService {
  Future<List<FitnessSpot>> fetchFitnessSpots(CookieRequest request, {String? gridId}) async {
    // Construct the full URL
    // Note: homeLocationsEndpoint in constants.dart is '/api/fitness-spots/'
    String url = '$djangoBaseUrl$homeLocationsEndpoint';
    if (gridId != null) {
      url += '?gridId=$gridId';
    }
    
    try {
      final response = await request.get(url);
      
      // The response from pbp_django_auth is usually the decoded JSON if it's a Map or List.
      // But let's handle it safely.
      
      if (response is Map<String, dynamic>) {
        if (response.containsKey('spots')) {
          final List<dynamic> spotsJson = response['spots'];
          return spotsJson.map((json) => FitnessSpot.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      // Handle errors or rethrow
      print('Error fetching fitness spots: $e');
      // Return empty list or throw, depending on desired behavior. 
      // For now, empty list to avoid crashing UI, but maybe rethrow to show error in FutureBuilder.
      throw Exception('Failed to load fitness spots: $e');
    }
  }

  Future<Map<String, double>?> fetchMapBoundaries(CookieRequest request) async {
    final url = '$djangoBaseUrl/api/map-boundaries/';
    try {
      final response = await request.get(url);
      if (response['north'] != null) {
        return {
          'north': (response['north'] as num).toDouble(),
          'south': (response['south'] as num).toDouble(),
          'east': (response['east'] as num).toDouble(),
          'west': (response['west'] as num).toDouble(),
        };
      }
      return null;
    } catch (e) {
      print('Error fetching map boundaries: $e');
      return null;
    }
  }
}
