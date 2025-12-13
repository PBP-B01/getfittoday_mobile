import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/event.dart'; // Pastikan path ini sesuai dengan letak file model Event kamu

// GANTI URL INI SESUAI ENV KITA:D
// Jika pakai Emulator Android: gunakan 'http://10.0.2.2:8000'
// Jika pakai Browser/iOS Simulator: gunakan 'http://127.0.0.1:8000' atau 'http://localhost:8000'
const String baseUrl = 'http://localhost:8000';

// 1. Fetch List Event berdasarkan Community ID
Future<List<Event>> fetchEvents(CookieRequest request, int communityId) async {
  // URL ini sesuai dengan routing Django: /event/api/community/<id>/
  final response = await request.get('$baseUrl/event/api/community/$communityId/');

  // Logic parsing response
  // Di Django views.py, response sukses formatnya: {"success": true, "events": [...]}
  if (response['success'] == true) {
    List<dynamic> listEvents = response['events'];

    // Konversi JSON list menjadi object List<Event>
    return listEvents.map((d) => Event.fromJson(d)).toList();
  } else {
    throw Exception('Gagal mengambil data event: ${response['error']}');
  }
}

// 2. Fungsi Join Event
Future<Map<String, dynamic>> joinEvent(CookieRequest request, int eventId) async {
  // URL: /event/ajax/join/<id>/
  // Kita pakai POST karena mengubah data di server
  final response = await request.post(
      '$baseUrl/event/ajax/join/$eventId/',
      {} // Body kosong, karena user diambil dari session cookies
  );

  // Kembalikan response mentah (JSON) biar UI bisa baca pesannya
  // Contoh return Django: {"status": "success", "message": "Berhasil bergabung..."}
  return response;
}

// 3. Fungsi Leave Event
Future<Map<String, dynamic>> leaveEvent(CookieRequest request, int eventId) async {
  // URL: /event/ajax/leave/<id>/
  final response = await request.post(
      '$baseUrl/event/ajax/leave/$eventId/',
      {}
  );
  return response;
}

Future<List<Map<String, dynamic>>> fetchAdminCommunities(CookieRequest request) async {
  // Pastikan URL benar untuk Web
  final url = '$baseUrl/event/api/my-admin-communities/';

  try {
    // Kita panggil manual biar bisa handle errornya
    final response = await request.get(url);

    // DEBUG: Cek tipe datanya
    if (response is String) {
      print("❌ ERROR: Server membalas dengan HTML!");
      print("--- ISI HTML MULAI ---");
      // Print 500 karakter pertama aja biar gak menuhin layar
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

// 2. Kirim Data Event Baru
Future<Map<String, dynamic>> createEvent(CookieRequest request, Map<String, dynamic> data) async {
  final response = await request.post(
    '$baseUrl/event/api/create/',
    jsonEncode(data), // Pastikan data di-encode jadi JSON
  );
  return response;
}