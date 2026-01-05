import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? phone;
  final String? address;
  final List<String> favoriteSpecies; // Danh sách loài yêu thích
  final List<String> savedNews; // Danh sách tin tức đã lưu
  final bool isAdmin; // Quyền admin
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.birthDate,
    this.phone,
    this.address,
    this.favoriteSpecies = const [],
    this.savedNews = const [],
    this.isAdmin = false,
    required this.createdAt,
    required this.updatedAt,
    this.isEmailVerified = false,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      phone: data['phone'],
      address: data['address'],
      favoriteSpecies: List<String>.from(data['favoriteSpecies'] ?? []),
      savedNews: List<String>.from(data['savedNews'] ?? []),
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEmailVerified: data['isEmailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'birthDate': birthDate,
      'phone': phone,
      'address': address,
      'favoriteSpecies': favoriteSpecies,
      'savedNews': savedNews,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isEmailVerified': isEmailVerified,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? avatarUrl,
    DateTime? birthDate,
    String? phone,
    String? address,
    List<String>? favoriteSpecies,
    List<String>? savedNews,
    bool? isAdmin,
    bool? isEmailVerified,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      favoriteSpecies: favoriteSpecies ?? this.favoriteSpecies,
      savedNews: savedNews ?? this.savedNews,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
