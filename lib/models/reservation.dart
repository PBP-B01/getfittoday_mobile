class Reservation {
  final String? id;
  final String title;
  final String location;
  final String status;
  final String scheduleDisplay;
  final String? notes;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool canCancel;

  Reservation({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.scheduleDisplay,
    required this.startDateTime,
    required this.endDateTime,
    this.notes,
    this.canCancel = false,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final idValue = json['id']?.toString();
    final rawStatus = json['status']?.toString().trim() ?? '';
    final normalizedStatus =
        rawStatus.isEmpty ? 'PENDING' : rawStatus.toUpperCase();

    // New API from MyBookingAPI: uses start/end/place_name.
    final hasNewApiFields =
        json.containsKey('start') || json.containsKey('place_name');
    if (hasNewApiFields) {
      final startIso = json['start']?.toString();
      final endIso = json['end']?.toString();
      final startDateTime = _parseIsoDateTime(startIso);
      final endDateTime = _parseIsoDateTime(endIso);
      final effectiveStatus = _effectiveStatusForTime(
        normalizedStatus,
        start: startDateTime,
        end: endDateTime,
      );

      final location = json['place_name']?.toString() ?? 'Lokasi belum diisi';
      final title = (json['title']?.toString().trim().isNotEmpty ?? false)
          ? json['title']!.toString()
          : location.isNotEmpty
              ? location
              : 'Booking';

      final schedule = _buildScheduleFromDateTimes(startDateTime, endDateTime);
      final canCancel = _parseBool(json['can_cancel']);

      return Reservation(
        id: idValue,
        title: title,
        location: location,
        status: effectiveStatus,
        scheduleDisplay:
            schedule.isEmpty ? 'Jadwal belum diisi' : schedule,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        notes: json['notes']?.toString(),
        canCancel: canCancel,
      );
    }

    // Legacy/local API: date + time + location.
    final rawDate = json['date']?.toString() ?? '';
    final rawTime = json['time']?.toString() ?? '';
    final parsedDateTime = _parseDateFromParts(rawDate, rawTime);
    final effectiveStatus = _effectiveStatusForTime(
      normalizedStatus,
      start: parsedDateTime,
      end: parsedDateTime != null
          ? parsedDateTime.add(const Duration(hours: 1))
          : null,
    );
    final schedule = _buildScheduleFromParts(rawDate, rawTime);

    final title = json['title']?.toString() ??
        json['class_name']?.toString() ??
        'Booking';

    return Reservation(
      id: idValue,
      title: title,
      location: json['location']?.toString() ?? 'Lokasi belum diisi',
      status: effectiveStatus,
      scheduleDisplay: schedule.isEmpty ? 'Jadwal belum diisi' : schedule,
      startDateTime: parsedDateTime,
      endDateTime:
          parsedDateTime != null ? parsedDateTime.add(const Duration(hours: 1)) : null,
      notes: json['notes']?.toString(),
      canCancel: _parseBool(json['can_cancel']),
    );
  }

  bool get isClosed {
    final normalized = status.toLowerCase();
    return normalized.contains('closed') ||
        normalized.contains('done') ||
        normalized.contains('finished') ||
        normalized.contains('complete') ||
        normalized.contains('cancel');
  }

  bool get isOngoing => !isClosed;
}

List<Reservation> sortReservationsByStatusAndTime(
  List<Reservation> reservations,
) {
  final sorted = List<Reservation>.from(reservations);
  sorted.sort(_reservationComparator);
  return sorted;
}

int _reservationComparator(Reservation a, Reservation b) {
  // Keep ongoing items first, closed items last.
  if (a.isClosed != b.isClosed) {
    return a.isClosed ? 1 : -1;
  }

  // Then order by scheduled time ascending.
  final aDate = a.startDateTime;
  final bDate = b.startDateTime;
  if (aDate != null && bDate != null) {
    return aDate.compareTo(bDate);
  }
  if (aDate != null) return -1;
  if (bDate != null) return 1;
  return 0;
}

DateTime? _parseDateFromParts(String rawDate, String rawTime) {
  if (rawDate.isEmpty) return null;
  final dateParts = rawDate.split(RegExp(r'[-/]'));
  if (dateParts.length < 3) return null;

  final year = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final day = int.tryParse(dateParts[2]);
  if (year == null || month == null || day == null) return null;

  int hour = 0;
  int minute = 0;
  if (rawTime.isNotEmpty) {
    final timeParts = rawTime.split(':');
    hour = int.tryParse(timeParts[0]) ?? 0;
    if (timeParts.length > 1) {
      minute = int.tryParse(timeParts[1]) ?? 0;
    }
  }

  return DateTime(year, month, day, hour, minute);
}

DateTime? _parseIsoDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    return DateTime.parse(iso).toLocal();
  } catch (_) {
    return null;
  }
}

String _buildScheduleFromParts(String rawDate, String rawTime) {
  if (rawDate.isEmpty && rawTime.isEmpty) return '';
  if (rawDate.isEmpty) return rawTime;
  if (rawTime.isEmpty) return rawDate;
  return '$rawDate at $rawTime';
}

String _buildScheduleFromDateTimes(DateTime? start, DateTime? end) {
  if (start == null && end == null) return '';
  if (start == null) return '';

  String two(int v) => v.toString().padLeft(2, '0');

  final datePart =
      '${start.year.toString().padLeft(4, '0')}-${two(start.month)}-${two(start.day)}';
  final startTime = '${two(start.hour)}:${two(start.minute)}';

  if (end == null) {
    return '$datePart $startTime';
  }

  final endTime = '${two(end.hour)}:${two(end.minute)}';
  return '$datePart $startTime - $endTime';
}

bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  final asString = value.toString().toLowerCase().trim();
  return asString == 'true' || asString == '1' || asString == 'yes';
}

String _effectiveStatusForTime(
  String currentStatus, {
  DateTime? start,
  DateTime? end,
}) {
  // Auto-cancel pending bookings yang sudah lewat waktunya.
  final upper = currentStatus.toUpperCase();
  final bool isPending = upper.contains('PENDING');
  if (!isPending) return currentStatus;

  final now = DateTime.now();
  if (end != null && end.isBefore(now)) return 'CANCELLED';
  if (start != null && start.isBefore(now)) return 'CANCELLED';
  return currentStatus;
}
