import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';
import '../models/user_model.dart';
import '../models/conservation_area_model.dart';
import '../models/sighting_model.dart';
import '../models/conservation_action_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String newsCollection = 'news';
  final String usersCollection = 'users';
  final String conservationAreasCollection = 'conservation_areas';
  final String sightingsCollection = 'sightings';
  final String conservationActionsCollection = 'conservation_actions';

  // ========== NEWS CRUD ==========

  // Lấy danh sách tin tức
  Future<List<News>> getAllNews() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection(newsCollection)
          .where('isPublished', isEqualTo: true)
          .orderBy('publishDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => News.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error getting news: $e');
      return [];
    }
  }

  // Lấy tin tức theo danh mục
  Future<List<News>> getNewsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection(newsCollection)
          .where('category', isEqualTo: category)
          .where('isPublished', isEqualTo: true)
          .orderBy('publishDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => News.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error getting news by category: $e');
      return [];
    }
  }

  // Thêm tin tức mới
  Future<String> addNews(News news) async {
    try {
      DocumentReference docRef = await _db.collection(newsCollection).add(news.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding news: $e');
      return '';
    }
  }

  // Cập nhật tin tức
  Future<bool> updateNews(News news) async {
    try {
      await _db.collection(newsCollection).doc(news.id).update(news.toFirestore());
      return true;
    } catch (e) {
      print('Error updating news: $e');
      return false;
    }
  }

  // Xóa tin tức
  Future<bool> deleteNews(String id) async {
    try {
      await _db.collection(newsCollection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting news: $e');
      return false;
    }
  }

  // ========== USER CRUD ==========

  // Lấy thông tin user theo ID
  Future<AppUser?> getUserById(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection(usersCollection).doc(id).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Tạo user mới
  Future<bool> createUser(AppUser user) async {
    try {
      await _db.collection(usersCollection).doc(user.id).set(user.toFirestore());
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // Cập nhật thông tin user
  Future<bool> updateUser(AppUser user) async {
    try {
      await _db.collection(usersCollection).doc(user.id).update(user.toFirestore());
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

}
