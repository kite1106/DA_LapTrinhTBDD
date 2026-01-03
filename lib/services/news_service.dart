import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_model.dart';

class NewsService {
  final FirebaseFirestore _db;

  NewsService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<List<News>> getAllNews({bool onlyPublished = true}) async {
    try {
      Query query = _db.collection('news');

      if (onlyPublished) {
        query = query.where('isPublished', isEqualTo: true);
      }

      final snapshot = await query.orderBy('publishDate', descending: true).get();
      return snapshot.docs
          .map((doc) => News.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting news: $e');
      return [];
    }
  }

  Future<List<News>> getNewsByCategory(String category, {bool onlyPublished = true}) async {
    try {
      Query query = _db.collection('news').where('category', isEqualTo: category);

      if (onlyPublished) {
        query = query.where('isPublished', isEqualTo: true);
      }

      final snapshot = await query.orderBy('publishDate', descending: true).get();
      return snapshot.docs
          .map((doc) => News.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting news by category: $e');
      return [];
    }
  }

  Future<String> addNews(News news) async {
    try {
      final docRef = await _db.collection('news').add(news.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding news: $e');
      return '';
    }
  }

  Future<bool> updateNews(News news) async {
    try {
      await _db.collection('news').doc(news.id).update(news.toFirestore());
      return true;
    } catch (e) {
      print('Error updating news: $e');
      return false;
    }
  }

  Future<bool> deleteNews(String id) async {
    try {
      await _db.collection('news').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting news: $e');
      return false;
    }
  }
}
