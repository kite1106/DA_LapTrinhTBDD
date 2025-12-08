import 'package:cloud_firestore/cloud_firestore.dart';

class Sighting {
  final String id;
  final String speciesId; // FK to species
  final String userId; // FK to users
  final Map<String, double> location; // {lat: 10.0, lng: 106.0}
  final DateTime date;
  final String description;
  final String imageUrl;
  final bool isVerified;
  final String? verifiedBy; // Admin user ID
  final DateTime? verifiedAt;
  final String environment; // Rừng, sông, đồng bằng...
  final int count; // Số lượng quan sát
  final List<String> tags; // Tags mô tả
  final DateTime createdAt;
  final DateTime updatedAt;

  Sighting({
    required this.id,
    required this.speciesId,
    required this.userId,
    required this.location,
    required this.date,
    required this.description,
    required this.imageUrl,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    required this.environment,
    this.count = 1,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sighting.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Sighting(
      id: documentId,
      speciesId: data['speciesId'] ?? '',
      userId: data['userId'] ?? '',
      location: Map<String, double>.from(data['location'] ?? {'lat': 0.0, 'lng': 0.0}),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isVerified: data['isVerified'] ?? false,
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      environment: data['environment'] ?? '',
      count: data['count'] ?? 1,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'speciesId': speciesId,
      'userId': userId,
      'location': location,
      'date': date,
      'description': description,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt,
      'environment': environment,
      'count': count,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
