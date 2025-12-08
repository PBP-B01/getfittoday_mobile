import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/reservation.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class ReservationService {
  Future<List<Reservation>> fetchMine(CookieRequest request) async {
    final tried = <String>[];
    final errors = <String>[];
    final candidates = <String>{
      bookingListEndpoint,
      ...bookingListEndpointCandidates,
    }.where((path) => path.isNotEmpty).toList();

    for (final endpoint in candidates) {
      final url = '$djangoBaseUrl$endpoint';
      tried.add(url);
      try {
        final raw = await request.get(url) as dynamic;
        final reservations = _parseReservations(raw);
        return sortReservationsByStatusAndTime(reservations);
      } catch (e) {
        errors.add('$url -> $e');
      }
    }

    throw FormatException(
      'Semua endpoint booking gagal diakses. Dicoba:\n${tried.join("\n")}\nError:\n${errors.join("\n")}\nPastikan jalur URL sesuai dengan project Django GetFitToday (cek booking/urls.py).',
    );
  }

  List<Reservation> _parseReservations(dynamic raw) {
    if (raw is String && raw.trim().startsWith('<')) {
      throw const FormatException(
        'Response HTML terdeteksi (mungkin endpoint salah atau belum login). Pastikan endpoint mengembalikan JSON.',
      );
    }

    List<dynamic> dataList = [];
    if (raw is List) {
      dataList = raw;
    } else if (raw is Map && raw['data'] is List) {
      dataList = raw['data'];
    } else if (raw is Map && raw['results'] is List) {
      dataList = raw['results'];
    }

    return dataList
        .whereType<Map<String, dynamic>>()
        .map((json) => Reservation.fromJson(json))
        .toList();
  }
}
