// File: lib/community/models/event.dart
import 'dart:convert';

List<Event> eventFromJson(String str) => List<Event>.from(json.decode(str).map((x) => Event.fromJson(x)));

String eventToJson(List<Event> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Event {
  int id;
  String name;
  String description;
  DateTime date;       // Untuk sorting/logic
  String dateDisplay;  // Untuk tampilan UI (Dari Django: "12 December 2025, 10:00")
  String location;
  int participantCount;
  bool isPast;
  bool registrationOpen;
  bool canJoin;        // Penting untuk tombol Join
  bool isParticipant;  // Penting untuk tombol Leave
  bool canEdit;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.dateDisplay,
    required this.location,
    required this.participantCount,
    required this.isPast,
    required this.registrationOpen,
    required this.canJoin,
    required this.isParticipant,
    required this.canEdit,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Parsing tanggal dari format Django "YYYY-MM-DD HH:MM"
    // Kita ganti spasi jadi 'T' biar bisa dibaca DateTime.parse Dart
    String rawDate = json["date"];
    if (!rawDate.contains('T')) {
      rawDate = rawDate.replaceFirst(' ', 'T');
    }

    return Event(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      date: DateTime.parse(rawDate),
      dateDisplay: json["date_display"] ?? "",
      location: json["location"],
      participantCount: json["participant_count"] ?? 0,
      isPast: json["is_past"] ?? false,
      registrationOpen: json["registration_open"] ?? false,
      canJoin: json["can_join"] ?? false,
      isParticipant: json["is_participant"] ?? false,
      canEdit: json["can_edit"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "date": date.toIso8601String(),
    "date_display": dateDisplay,
    "location": location,
    "participant_count": participantCount,
    "is_past": isPast,
    "registration_open": registrationOpen,
    "can_join": canJoin,
    "is_participant": isParticipant,
    "can_edit": canEdit,
  };
}