import 'dart:convert';

List<Community> communityFromJson(String str) => List<Community>.from(json.decode(str).map((x) => Community.fromJson(x)));

String communityToJson(List<Community> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Community {
    int id;
    String name;
    final String shortDescription;
    String description;
    String contactInfo;
    String? category;
    FitnessSpot? fitnessSpot;
    int membersCount;
    String? image;
    bool isMember;
    DateTime createdAt;

    Community({
        required this.id,
        required this.name,
        required this.shortDescription,
        required this.description,
        required this.contactInfo,
        this.category,
        this.fitnessSpot,
        required this.membersCount,
        this.image,
        required this.isMember,
        required this.createdAt,
    });

    factory Community.fromJson(Map<String, dynamic> json) => Community(
        id: json["id"],
        name: json["name"],
        shortDescription: json['short_description'] ?? "",
        description: json["description"],
        contactInfo: json["contact_info"],
        category: json["category"],
        fitnessSpot: json["fitness_spot"] == null ? null : FitnessSpot.fromJson(json["fitness_spot"]),
        membersCount: json["members_count"],
        image: json["image"],
        isMember: json["is_member"] ?? false,
        createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : DateTime.now(),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "contact_info": contactInfo,
        "category": category,
        "fitness_spot": fitnessSpot?.toJson(),
        "members_count": membersCount,
        "image": image,
        "is_member": isMember,
        "created_at": createdAt.toIso8601String(),
    };
}

class FitnessSpot {
    String id;
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
        id: json["id"].toString(),
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
