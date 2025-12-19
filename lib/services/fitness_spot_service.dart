
import 'dart:convert';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/fitness_spot.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class FitnessSpotService {
  Future<List<FitnessSpot>> fetchFitnessSpots(CookieRequest request, {String? gridId}) async {
    String url = '$djangoBaseUrl$homeLocationsEndpoint';
    if (gridId != null) {
      url += '?gridId=$gridId';
    }

    try {
      final response = await request.get(url);


      if (response is Map<String, dynamic>) {
        if (response.containsKey('spots')) {
          final List<dynamic> spotsJson = response['spots'];
          return spotsJson.map((json) => FitnessSpot.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching fitness spots: $e');
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

  Future<bool> createFitnessSpot(CookieRequest request, Map<String, dynamic> data) async {
    final url = '$djangoBaseUrl$homeLocationsEndpoint';
    try {
      final response = await request.post(url, jsonEncode(data));
      if (response['status'] == 'success' || response['id'] != null || response['place_id'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating fitness spot: $e');
      return false;
    }
  }
}
