import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const String _configuredBaseUrl =
    String.fromEnvironment('DJANGO_BASE_URL', defaultValue: '');
const String _webBaseUrl = 'http://localhost:8000';
const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

/// Adjust these if your Django booking-reservation URLs are different.
const String bookingListEndpoint =
    '/booking-reservation/api/reservations/'; // GET
const String bookingCreateEndpoint =
    '/booking-reservation/api/reservations/create/'; // POST

String get djangoBaseUrl {
  if (_configuredBaseUrl.isNotEmpty) {
    return _configuredBaseUrl;
  }
  if (kIsWeb) {
    return _webBaseUrl;
  }
  return _androidEmulatorBaseUrl;
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
