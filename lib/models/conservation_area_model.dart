class ConservationArea {
  final String id;
  final String name;
  final String description;
  final double area; // Diện tích (km²)
  final int establishedYear;
  final List<String> species; // Danh sách loài trong khu vực
  final Map<String, double> location; // {lat: 10.0, lng: 106.0}
  final String imageUrl;
  final String type; // Quốc gia, Tự nhiên, Động vật
  final String status; // Đang hoạt động, Bảo vệ
  final DateTime createdAt;
  final DateTime updatedAt;

  ConservationArea({
    required this.id,
    required this.name,
    required this.description,
    required this.area,
    required this.establishedYear,
    required this.species,
    required this.location,
    required this.imageUrl,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConservationArea.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Handle both Firebase Timestamp and String date formats
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return ConservationArea(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      area: (data['area'] ?? 0.0).toDouble(),
      establishedYear: data['establishedYear'] ?? 0,
      species: List<String>.from(data['species'] ?? []),
      location: Map<String, double>.from(data['location'] ?? {'lat': 0.0, 'lng': 0.0}),
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'area': area,
      'establishedYear': establishedYear,
      'species': species,
      'location': location,
      'imageUrl': imageUrl,
      'type': type,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
