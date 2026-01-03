import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Quản lý danh sách yêu thích (động vật + tin tức) và đồng bộ Firestore theo user.
class FavoritesProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Set<String> _animalIds = <String>{};
  final Set<String> _newsIds = <String>{};

  String? _userId;
  bool _loading = false;
  bool _loaded = false;

  bool get isLoading => _loading;
  List<String> get animalIds => _animalIds.toList(growable: false);
  List<String> get newsIds => _newsIds.toList(growable: false);

  // Gọi khi user thay đổi (đăng nhập/đăng xuất)
  Future<void> setUser(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    _loaded = false;
    _animalIds.clear();
    _newsIds.clear();
    notifyListeners();
    if (userId != null) {
      await _loadFromFirestore(userId);
    }
  }

  bool isAnimalFavorite(String id) => _animalIds.contains(id);
  bool isNewsFavorite(String id) => _newsIds.contains(id);

  Future<void> toggleAnimal(String id) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;
    _userId ??= uid;
    if (_animalIds.contains(id)) {
      _animalIds.remove(id);
    } else {
      _animalIds.add(id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> toggleNews(String id) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;
    _userId ??= uid;
    if (_newsIds.contains(id)) {
      _newsIds.remove(id);
    } else {
      _newsIds.add(id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _loadFromFirestore(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final doc = await _db.collection('users').doc(userId).collection('meta').doc('favorites').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final animals = List<String>.from(data['animals'] ?? const []);
        final news = List<String>.from(data['news'] ?? const []);
        _animalIds
          ..clear()
          ..addAll(animals);
        _newsIds
          ..clear()
          ..addAll(news);
      }
      _loaded = true;
    } catch (_) {
      // bỏ qua, vẫn cho phép local state
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (_userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('meta')
          .doc('favorites')
          .set({
        'animals': animalIds,
        'news': newsIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // nếu lỗi ghi, không crash, state vẫn giữ
    }
  }
}
