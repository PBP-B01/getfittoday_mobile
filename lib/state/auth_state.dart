import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  String? _username;
  bool _isAdmin = false;

  String? get username => _username;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => (_username ?? '').isNotEmpty;

  void clear() {
    _username = null;
    _isAdmin = false;
    notifyListeners();
  }

  void setFromLoginResponse(
    Map<String, dynamic> response, {
    String? fallbackUsername,
  }) {
    _username = _extractUsername(response) ?? fallbackUsername;
    _isAdmin = _extractIsAdmin(response);
    notifyListeners();
  }
}

String? _extractUsername(Map<String, dynamic> data) {
  final value = data['username'];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  final user = data['user'];
  if (user is Map) {
    final nested = user['username'];
    if (nested is String && nested.trim().isNotEmpty) return nested.trim();
  }
  return null;
}

bool _extractIsAdmin(Map<String, dynamic> data) {
  // Common boolean flags.
  for (final key in <String>[
    'is_admin',
    'isAdmin',
    'admin',
    'is_superuser',
    'isSuperuser',
    'is_staff',
    'isStaff',
  ]) {
    if (data.containsKey(key)) {
      return _parseBool(data[key]);
    }
  }

  // Nested user payloads (e.g. { user: {...} }).
  final user = data['user'];
  if (user is Map<String, dynamic>) {
    return _extractIsAdmin(user);
  }

  // Role strings.
  final dynamic roleValue = data['role'] ?? data['user_role'] ?? data['userRole'];
  if (roleValue != null) {
    final role = roleValue.toString().toLowerCase();
    if (role.contains('admin') ||
        role.contains('staff') ||
        role.contains('superuser')) {
      return true;
    }
  }

  // Group lists.
  final groups = data['groups'];
  if (groups is List) {
    for (final g in groups) {
      final name = g?.toString().toLowerCase();
      if (name == null) continue;
      if (name.contains('admin') || name.contains('staff')) return true;
    }
  }

  return false;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value == null) return false;
  final v = value.toString().trim().toLowerCase();
  return v == 'true' || v == '1' || v == 'yes' || v == 'y';
}
