import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedData {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addSampleAnimals() async {
    final sampleAnimals = [
      {
        'name': 'Hổ Đông Dương',
        'species': 'Panthera tigris corbetti',
        'description': 'Loài hổ quý hiếm sống ở rừng nhiệt đới',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef7',
        'isRare': true,
        'location': const GeoPoint(10.8231, 106.6297),
      },
      {
        'name': 'Voi châu Á',
        'species': 'Elephas maximus',
        'description': 'Loài voi lớn nhất châu Á',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef8',
        'isRare': true,
        'location': const GeoPoint(11.9414, 108.4584),
      },
      {
        'name': 'Khỉ đuôi dài',
        'species': 'Macaca fascicularis',
        'description': 'Loài khỉ phổ biến ở Đông Nam Á',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef9',
        'isRare': false,
        'location': const GeoPoint(12.2383, 109.1967),
      },
    ];

    try {
      for (final animal in sampleAnimals) {
        await _db.collection('animals').add({
          ...animal,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid,
        });
      }
      print('Đã thêm 3 mẫu động vật thành công!');
    } catch (e) {
      print('Lỗi thêm dữ liệu mẫu: $e');
    }
  }

  Future<void> addAllSampleData() async {
    await addSampleAnimals();
    print('Đã thêm tất cả dữ liệu mẫu thành công!');
  }
}
