import 'package:cloud_firestore/cloud_firestore.dart';

class Species {
  final String id;
  final String commonName; // Tên thường gọi
  final String scientificName; // Tên khoa học
  final String family; // Họ
  final String order; // Bộ
  final String category; // Nhóm loài (Thú, Chim, Bò sát...)
  final String conservationStatus; // Mức độ nguy cấp (CR, EN, VU...)
  final String description; // Mô tả đặc điểm sinh học
  final String distribution; // Phân bố địa lý
  final String population; // Dân số
  final String threats; // Nguyên nhân suy giảm
  final String conservationActions; // Hành động bảo tồn
  final String habitat; // Môi trường sống
  final String imageUrl; // URL hình ảnh
  final List<String> locations; // Vị trí GPS [lat, lng]
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite; // Yêu thích của người dùng

  Species({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.family,
    required this.order,
    required this.category,
    required this.conservationStatus,
    required this.description,
    required this.distribution,
    required this.population,
    required this.threats,
    required this.conservationActions,
    required this.habitat,
    required this.imageUrl,
    required this.locations,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  // Factory constructor từ Firestore
  factory Species.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Species(
      id: documentId,
      commonName: data['commonName'] ?? '',
      scientificName: data['scientificName'] ?? '',
      family: data['family'] ?? '',
      order: data['order'] ?? '',
      category: data['category'] ?? '',
      conservationStatus: data['conservationStatus'] ?? '',
      description: data['description'] ?? '',
      distribution: data['distribution'] ?? '',
      population: data['population'] ?? '',
      threats: data['threats'] ?? '',
      conservationActions: data['conservationActions'] ?? '',
      habitat: data['habitat'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      locations: List<String>.from(data['locations'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  // Chuyển thành Map để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'commonName': commonName,
      'scientificName': scientificName,
      'family': family,
      'order': order,
      'category': category,
      'conservationStatus': conservationStatus,
      'description': description,
      'distribution': distribution,
      'population': population,
      'threats': threats,
      'conservationActions': conservationActions,
      'habitat': habitat,
      'imageUrl': imageUrl,
      'locations': locations,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isFavorite': isFavorite,
    };
  }

  // Copy with để cập nhật
  Species copyWith({
    String? commonName,
    String? scientificName,
    String? family,
    String? order,
    String? category,
    String? conservationStatus,
    String? description,
    String? distribution,
    String? population,
    String? threats,
    String? conservationActions,
    String? habitat,
    String? imageUrl,
    List<String>? locations,
    bool? isFavorite,
  }) {
    return Species(
      id: id,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      order: order ?? this.order,
      category: category ?? this.category,
      conservationStatus: conservationStatus ?? this.conservationStatus,
      description: description ?? this.description,
      distribution: distribution ?? this.distribution,
      population: population ?? this.population,
      threats: threats ?? this.threats,
      conservationActions: conservationActions ?? this.conservationActions,
      habitat: habitat ?? this.habitat,
      imageUrl: imageUrl ?? this.imageUrl,
      locations: locations ?? this.locations,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Lấy màu sắc theo mức độ nguy cấp
  String getStatusColor() {
    switch (conservationStatus.toUpperCase()) {
      case 'CR':
        return '#FF0000'; // Đỏ - Cực kỳ nguy cấp
      case 'EN':
        return '#FF8C00'; // Cam - Nguy cấp
      case 'VU':
        return '#FFD700'; // Vàng - Dễ bị tổn thương
      case 'NT':
        return '#87CEEB'; // Xanh nhạt - Gần bị đe dọa
      case 'LC':
        return '#228B22'; // Xanh lá - Ít quan tâm
      default:
        return '#808080'; // Xám - Không có dữ liệu
    }
  }

  // Lấy tên đầy đủ của mức độ nguy cấp
  String getStatusName() {
    switch (conservationStatus.toUpperCase()) {
      case 'CR':
        return 'Cực kỳ nguy cấp';
      case 'EN':
        return 'Nguy cấp';
      case 'VU':
        return 'Dễ bị tổn thương';
      case 'NT':
        return 'Gần bị đe dọa';
      case 'LC':
        return 'Ít quan tâm';
      default:
        return 'Không có dữ liệu';
    }
  }
}
