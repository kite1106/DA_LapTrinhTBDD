import 'package:cloud_firestore/cloud_firestore.dart';

class ConservationAction {
  final String id;
  final String title;
  final String description;
  final String organization;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> speciesInvolved; // Danh sách loài liên quan
  final String status; // Đang thực hiện, Hoàn thành, Lên kế hoạch
  final String type; // Cứu hộ, Bảo vệ, Nghiên cứu, Trồng rừng
  final String location; // Địa điểm thực hiện
  final List<String> participants; // Người tham gia
  final String imageUrl;
  final List<String> requiredSkills; // Kỹ năng cần thiết
  final String contactInfo; // Thông tin liên hệ
  final DateTime createdAt;
  final DateTime updatedAt;

  ConservationAction({
    required this.id,
    required this.title,
    required this.description,
    required this.organization,
    required this.startDate,
    this.endDate,
    required this.speciesInvolved,
    required this.status,
    required this.type,
    required this.location,
    this.participants = const [],
    required this.imageUrl,
    this.requiredSkills = const [],
    required this.contactInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConservationAction.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ConservationAction(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      organization: data['organization'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      speciesInvolved: List<String>.from(data['speciesInvolved'] ?? []),
      status: data['status'] ?? '',
      type: data['type'] ?? '',
      location: data['location'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      contactInfo: data['contactInfo'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'organization': organization,
      'startDate': startDate,
      'endDate': endDate,
      'speciesInvolved': speciesInvolved,
      'status': status,
      'type': type,
      'location': location,
      'participants': participants,
      'imageUrl': imageUrl,
      'requiredSkills': requiredSkills,
      'contactInfo': contactInfo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String getStatusColor() {
    switch (status.toLowerCase()) {
      case 'đang thực hiện':
        return '#008000'; // Xanh lá
      case 'hoàn thành':
        return '#0000FF'; // Xanh dương
      case 'lên kế hoạch':
        return '#FFA500'; // Cam
      default:
        return '#808080'; // Xám
    }
  }
}
