import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnimalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<void> addAnimal({
    required String name,
    required String species,
    required String description,
    required String imageUrl,
    required bool isRare,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _db.collection('animals').add({
        'name': name,
        'species': species,
        'description': description,
        'imageUrl': imageUrl,
        'isRare': isRare,
        'location': GeoPoint(latitude, longitude),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });
      print('Đã thêm động vật: $name');
    } catch (e) {
      print('Lỗi thêm động vật: $e');
      rethrow;
    }
  }

  Future<void> updateAnimal({
    required String id,
    required String name,
    required String species,
    required String description,
    required String imageUrl,
    required bool isRare,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _db.collection('animals').doc(id).update({
        'name': name,
        'species': species,
        'description': description,
        'imageUrl': imageUrl,
        'isRare': isRare,
        'location': GeoPoint(latitude, longitude),
      });
      print('Đã cập nhật động vật: $name');
    } catch (e) {
      print('Lỗi cập nhật động vật: $e');
      rethrow;
    }
  }
  
  Stream<QuerySnapshot> getAnimals() {
    return _db
        .collection('animals')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  Future<void> addAnalysisResult({
    required String animalId,
    required String imageUrl,
    required double confidence,
    required Map<String, dynamic> analysisData,
  }) async {
    try {
      await _db.collection('analysis_results').add({
        'animalId': animalId,
        'imageUrl': imageUrl,
        'confidence': confidence,
        'analysisData': analysisData,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });
      print('Đã thêm kết quả phân tích');
    } catch (e) {
      print('Lỗi thêm kết quả phân tích: $e');
      rethrow;
    }
  }
  
  Stream<QuerySnapshot> getUserAnalysisHistory() {
    return _db
        .collection('analysis_results')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
