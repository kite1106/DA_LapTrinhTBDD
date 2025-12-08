import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/species_model.dart';
import '../models/news_model.dart';
import '../models/user_model.dart';
import '../models/conservation_area_model.dart';
import '../models/sighting_model.dart';
import '../models/conservation_action_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String speciesCollection = 'species';
  final String newsCollection = 'news';
  final String usersCollection = 'users';
  final String conservationAreasCollection = 'conservation_areas';
  final String sightingsCollection = 'sightings';
  final String conservationActionsCollection = 'conservation_actions';
  
  // ========== SPECIES CRUD ==========
  
  // Lấy danh sách tất cả loài
  Future<List<Species>> getAllSpecies() async {
    try {
      QuerySnapshot snapshot = await _db.collection(speciesCollection).get();
      return snapshot.docs.map((doc) => Species.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error getting species: $e');
      return [];
    }
  }

  // Lấy loài theo ID
  Future<Species?> getSpeciesById(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection(speciesCollection).doc(id).get();
      if (doc.exists) {
        return Species.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting species by ID: $e');
      return null;
    }
  }

  // Tìm kiếm loài theo tên
  Future<List<Species>> searchSpecies(String query) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection(speciesCollection)
          .where('commonName', isGreaterThanOrEqualTo: query)
          .where('commonName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      return snapshot.docs.map((doc) => Species.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error searching species: $e');
      return [];
    }
  }

  // Lọc loài theo mức độ nguy cấp
  Future<List<Species>> getSpeciesByStatus(String status) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection(speciesCollection)
          .where('conservationStatus', isEqualTo: status)
          .get();
      return snapshot.docs.map((doc) => Species.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error filtering species by status: $e');
      return [];
    }
  }

  // Thêm loài mới
  Future<String> addSpecies(Species species) async {
    try {
      DocumentReference docRef = await _db.collection(speciesCollection).add(species.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding species: $e');
      return '';
    }
  }

  // Cập nhật loài
  Future<bool> updateSpecies(Species species) async {
    try {
      await _db.collection(speciesCollection).doc(species.id).update(species.toFirestore());
      return true;
    } catch (e) {
      print('Error updating species: $e');
      return false;
    }
  }

  // Xóa loài
  Future<bool> deleteSpecies(String id) async {
    try {
      await _db.collection(speciesCollection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting species: $e');
      return false;
    }
  }

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

  // Thêm loài vào danh sách yêu thích
  Future<bool> addToFavorites(String userId, String speciesId) async {
    try {
      await _db.collection(usersCollection).doc(userId).update({
        'favoriteSpecies': FieldValue.arrayUnion([speciesId])
      });
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  // Xóa loài khỏi danh sách yêu thích
  Future<bool> removeFromFavorites(String userId, String speciesId) async {
    try {
      await _db.collection(usersCollection).doc(userId).update({
        'favoriteSpecies': FieldValue.arrayRemove([speciesId])
      });
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Lấy danh sách loài yêu thích của user
  Future<List<Species>> getFavoriteSpecies(String userId) async {
    try {
      DocumentSnapshot userDoc = await _db.collection(usersCollection).doc(userId).get();
      if (userDoc.exists) {
        List<String> favoriteIds = List<String>.from(userDoc.get('favoriteSpecies') ?? []);
        if (favoriteIds.isEmpty) return [];
        
        QuerySnapshot speciesSnapshot = await _db
            .collection(speciesCollection)
            .where(FieldPath.documentId, whereIn: favoriteIds)
            .get();
        return speciesSnapshot.docs.map((doc) => Species.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting favorite species: $e');
      return [];
    }
  }

  // Thống kê số lượng loài theo mức độ nguy cấp
  Future<Map<String, int>> getSpeciesStatistics() async {
    try {
      QuerySnapshot snapshot = await _db.collection(speciesCollection).get();
      Map<String, int> stats = {};
      
      for (var doc in snapshot.docs) {
        String status = doc.get('conservationStatus') ?? 'Unknown';
        stats[status] = (stats[status] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      print('Error getting species statistics: $e');
      return {};
    }
  }
}
