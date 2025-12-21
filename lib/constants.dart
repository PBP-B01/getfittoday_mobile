import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String _configuredBaseUrl =
    String.fromEnvironment('DJANGO_BASE_URL', defaultValue: '');
const String _defaultProdBaseUrl =
    'https://samuel-indriano-get-fit-today.pbp.cs.ui.ac.id';

String _normalizeBaseUrl(String value) {
  var normalized = value.trim();
  if (normalized.isEmpty) return '';

  if ((normalized.startsWith('"') && normalized.endsWith('"')) ||
      (normalized.startsWith("'") && normalized.endsWith("'"))) {
    normalized = normalized.substring(1, normalized.length - 1).trim();
  }

  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }

  return normalized;
}

const String homeLocationsEndpoint = '/api/fitness-spots/';

const String _bookingListEndpointEnv =
    String.fromEnvironment('BOOKING_LIST_ENDPOINT', defaultValue: '');
const String _bookingCreateEndpointEnv =
    String.fromEnvironment('BOOKING_CREATE_ENDPOINT', defaultValue: '');
const String _defaultBookingListEndpoint = '/booking/api/mine/';
const List<String> bookingListEndpointCandidates = <String>[
  _defaultBookingListEndpoint,
  '/booking/api/bookings/',
  '/booking/api/list/',
];
const String _defaultBookingCreateEndpoint = '/booking/book/';

String get bookingListEndpoint {
  if (_bookingListEndpointEnv.isNotEmpty) return _bookingListEndpointEnv;
  return _defaultBookingListEndpoint;
}

String get bookingCreateEndpoint {
  if (_bookingCreateEndpointEnv.isNotEmpty) return _bookingCreateEndpointEnv;
  return _defaultBookingCreateEndpoint;
}

String get djangoBaseUrl {
  final configured = _normalizeBaseUrl(_configuredBaseUrl);
  if (configured.isNotEmpty) return configured;

  String envBaseUrl = '';
  try {
    envBaseUrl = dotenv.env['DJANGO_BASE_URL'] ?? '';
  } catch (_) {
    envBaseUrl = '';
  }
  final envConfigured = _normalizeBaseUrl(envBaseUrl);
  if (envConfigured.isNotEmpty) return envConfigured;

  return _defaultProdBaseUrl;
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
