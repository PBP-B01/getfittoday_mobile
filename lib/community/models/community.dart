// To parse this JSON data, do
// final community = communityFromJson(jsonString);

import 'dart:convert';

List<Community> communityFromJson(String str) => List<Community>.from(json.decode(str).map((x) => Community.fromJson(x)));

String communityToJson(List<Community> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Community {
    int id;
    String name;
    String description;
    String contactInfo;
    String? category;
    FitnessSpot? fitnessSpot;
    int membersCount;

    Community({
        required this.id,
        required this.name,
        required this.description,
        required this.contactInfo,
        this.category,
        this.fitnessSpot,
        required this.membersCount,
    });

    factory Community.fromJson(Map<String, dynamic> json) => Community(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        contactInfo: json["contact_info"],
        category: json["category"],
        fitnessSpot: json["fitness_spot"] == null ? null : FitnessSpot.fromJson(json["fitness_spot"]),
        membersCount: json["members_count"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "contact_info": contactInfo,
        "category": category,
        "fitness_spot": fitnessSpot?.toJson(),
        "members_count": membersCount,
    };
}

class FitnessSpot {
    int id;
    String name;
    String placeId;
    String address;

    FitnessSpot({
        required this.id,
        required this.name,
        required this.placeId,
        required this.address,
    });

    factory FitnessSpot.fromJson(Map<String, dynamic> json) => FitnessSpot(
        id: json["id"],
        name: json["name"],
        placeId: json["place_id"],
        address: json["address"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "place_id": placeId,
        "address": address,
    };
}