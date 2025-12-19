import 'dart:convert';

class Event {
    final String id;
    final String name;
    final String? image;
    final String description;
    final DateTime startingDate;
    final DateTime endingDate;
    final String user;
    final List<String> locations;
    final bool isOwner;

    Event({
        required this.id,
        required this.name,
        this.image,
        required this.description,
        required this.startingDate,
        required this.endingDate,
        required this.user,
        required this.locations,
        required this.isOwner,
    });

    factory Event.fromJson(Map<String, dynamic> json) {
        // Helper function to safely parse DateTime
        DateTime parseDateTime(dynamic value) {
            if (value == null) return DateTime.now();
            if (value is DateTime) return value;
            try {
                return DateTime.parse(value.toString());
            } catch (e) {
                return DateTime.now();
            }
        }

        return Event(
            id: json['id']?.toString() ?? '',
            name: json['name']?.toString() ?? '',
            image: json['image']?.toString(),
            description: json['description']?.toString() ?? '',
            startingDate: parseDateTime(json['starting_date']),
            endingDate: parseDateTime(json['ending_date']),
            user: json['user']?.toString() ?? '',
            locations: json['locations'] is List
                ? List<String>.from(json['locations'])
                : [],
            isOwner: json['is_owner'] == true,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'name': name,
            'image': image,
            'description': description,
            'starting_date': startingDate.toIso8601String(),
            'ending_date': endingDate.toIso8601String(),
            'user': user,
            'locations': locations,
            'is_owner': isOwner,
        };
    }
}

class Blog {
    final String id;
    final String title;
    final String? image;
    final String body;
    final String author;
    final bool isOwner;

    Blog({
        required this.id,
        required this.title,
        this.image,
        required this.body,
        required this.author,
        required this.isOwner,
    });

    factory Blog.fromJson(Map<String, dynamic> json) {
        return Blog(
            id: json['id']?.toString() ?? '',
            title: json['title']?.toString() ?? '',
            image: json['image']?.toString(),
            body: json['body']?.toString() ?? '',
            author: json['author']?.toString() ?? '',
            isOwner: json['is_owner'] == true,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'title': title,
            'image': image,
            'body': body,
            'author': author,
            'is_owner': isOwner,
        };
    }
}