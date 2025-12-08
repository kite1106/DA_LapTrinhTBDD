import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedData {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addSampleAnimals() async {
    final sampleAnimals = [
      {
        'name': 'Hổ Đông Dương',
        'species': 'Panthera tigris corbetti',
        'description': 'Loài hổ quý hiếm sống ở rừng nhiệt đới, có sọc vằn đặc trưng',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef7',
        'isRare': true,
        'location': const GeoPoint(10.8231, 106.6297),
      },
      {
        'name': 'Voi châu Á',
        'species': 'Elephas maximus',
        'description': 'Loài voi lớn nhất châu Á, có tai nhỏ và ngà dài',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef8',
        'isRare': true,
        'location': const GeoPoint(11.9414, 108.4584),
      },
      {
        'name': 'Khỉ đuôi dài',
        'species': 'Macaca fascicularis',
        'description': 'Loài khỉ thông minh, sống theo bầy đàn, có đuôi dài',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef9',
        'isRare': false,
        'location': const GeoPoint(12.2383, 109.1967),
      },
      {
        'name': 'Tê giác một sừng',
        'species': 'Rhinoceros sondaicus',
        'description': 'Loài tê giác cực kỳ quý hiếm, chỉ còn ít cá thể trong tự nhiên',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef0',
        'isRare': true,
        'location': const GeoPoint(8.4095, 106.6888),
      },
      {
        'name': 'Gấu ngựa',
        'species': 'Helarctos malayanus',
        'description': 'Loài gấu nhỏ nhất, có lốt hình chữ V trên ngực',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef1',
        'isRare': true,
        'location': const GeoPoint(13.7563, 100.5018),
      },
      {
        'name': 'Cò trắng',
        'species': 'Egretta garzetta',
        'description': 'Loài chim nước trắng muốt, thường sống ở vùng ngập nước',
        'imageUrl': 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef2',
        'isRare': false,
        'location': const GeoPoint(10.0452, 105.7469),
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
      print('Đã thêm 6 mẫu động vật thành công!');
    } catch (e) {
      print('Lỗi thêm dữ liệu mẫu: $e');
    }
  }

  Future<void> addAllSampleData() async {
    await addSampleAnimals();
    print('Đã thêm tất cả dữ liệu mẫu thành công!');
  }
}