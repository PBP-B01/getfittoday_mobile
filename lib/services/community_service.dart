import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/event.dart';

const String baseUrl = 'http://localhost:8000';

Future<List<Event>> fetchEvents(CookieRequest request, int communityId) async {
  final response = await request.get('$baseUrl/event/api/community/$communityId/');

  if (response['success'] == true) {
    List<dynamic> listEvents = response['events'];

    return listEvents.map((d) => Event.fromJson(d)).toList();
  } else {
    throw Exception('Gagal mengambil data event: ${response['error']}');
  }
}

Future<Map<String, dynamic>> joinEvent(CookieRequest request, int eventId) async {
  final response = await request.post(
      '$baseUrl/event/ajax/join/$eventId/',
      {}
  );

  return response;
}

Future<Map<String, dynamic>> leaveEvent(CookieRequest request, int eventId) async {
  final response = await request.post(
      '$baseUrl/event/ajax/leave/$eventId/',
      {}
  );
  return response;
}

Future<List<Map<String, dynamic>>> fetchAdminCommunities(CookieRequest request) async {
  final url = '$baseUrl/event/api/my-admin-communities/';

  try {
    final response = await request.get(url);

    if (response is String) {
      print("❌ ERROR: Server membalas dengan HTML!");
      print("--- ISI HTML MULAI ---");
      print(response.substring(0, response.length > 500 ? 500 : response.length));
      print("--- ISI HTML SELESAI ---");
      return [];
    }

    return List<Map<String, dynamic>>.from(response['communities']);
  } catch (e) {
    print("❌ Error Fetching: $e");
    return [];
  }
}

Future<Map<String, dynamic>> createEvent(CookieRequest request, Map<String, dynamic> data) async {
  final response = await request.post(
    '$baseUrl/event/api/create/',
    jsonEncode(data),
  );
  return response;
}
