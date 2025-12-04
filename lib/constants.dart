import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const String _configuredBaseUrl =
    String.fromEnvironment('DJANGO_BASE_URL', defaultValue: '');
const String _webBaseUrl = 'http://localhost:8000';
const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

/// Endpoint untuk data lokasi (fitness spots) dari Django home app.
/// Sesuaikan dengan project urls; jika home di-root, gunakan '/api/fitness-spots/'.
const String homeLocationsEndpoint = '/api/fitness-spots/'; // GET

/// Daftar booking milik user (lihat booking/urls.py -> api/mine/).
const String _bookingListEndpointEnv =
    String.fromEnvironment('BOOKING_LIST_ENDPOINT', defaultValue: '');
const String _bookingCreateEndpointEnv =
    String.fromEnvironment('BOOKING_CREATE_ENDPOINT', defaultValue: '');
const String _defaultBookingListEndpoint = '/booking/api/mine/'; // GET
/// Endpoint alternatif yang umum dipakai pada proyek Django GetFitToday.
const List<String> bookingListEndpointCandidates = <String>[
  _defaultBookingListEndpoint,
  '/booking/api/bookings/',
  '/booking/api/list/',
];
/// Endpoint membuat booking baru (booking/urls.py -> book/).
const String _defaultBookingCreateEndpoint = '/booking/book/'; // POST

String get bookingListEndpoint {
  if (_bookingListEndpointEnv.isNotEmpty) return _bookingListEndpointEnv;
  return _defaultBookingListEndpoint;
}

String get bookingCreateEndpoint {
  if (_bookingCreateEndpointEnv.isNotEmpty) return _bookingCreateEndpointEnv;
  return _defaultBookingCreateEndpoint;
}

String get djangoBaseUrl {
  if (_configuredBaseUrl.isNotEmpty) {
    return _configuredBaseUrl;
  }
  if (kIsWeb) {
    return _webBaseUrl;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android emulator exposes the host machine via 10.0.2.2.
      return _androidEmulatorBaseUrl;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      // Desktop & iOS simulators can talk to localhost directly.
      return _webBaseUrl;
  }
}

const Color primaryNavColor = Color(0xFF0E5A64);
const Color primaryNavDarkerColor = Color(0xFF07434B);
const Color titleColor = Color(0xFF1B2B5A);
const Color gradientStartColor = Color(0xFFEAF2FF);
const Color gradientEndColor = Color(0xFFBFD6F2);
const Color cardBorderColor = Color(0xFFC8DDF6);
const Color cardBorderStrongColor = Color(0xFFDDE7FF);
const Color inkWeakColor = Color(0xFF6B7A99);
const Color accentColor = Color(0xFFFFC107);
const Color accentDarkColor = Color(0xFFE0A106);
const Color inputBackgroundColor = Color(0xFFF8FBFF);
const Color inputTextColor = Color(0xFF0B2E55);
