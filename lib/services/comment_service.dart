import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CommentService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<QuerySnapshot> streamComments(String animalId) {
    return _db
        .collection('animals')
        .doc(animalId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addComment({
    required String animalId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    final display = user?.displayName?.trim();
    final email = user?.email?.trim();
    await _db.collection('animals').doc(animalId).collection('comments').add({
      'text': text,
      'userId': user?.uid,
      'userName': (display?.isNotEmpty == true)
          ? display
          : (email?.isNotEmpty == true ? email : 'Người dùng'),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> vote({
    required String animalId,
    required String commentId,
    required bool isLike,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('User not logged in');
    }
    final ref = _db.collection('animals').doc(animalId).collection('comments').doc(commentId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final likes = List<String>.from(data['likes'] ?? const []);
      final dislikes = List<String>.from(data['dislikes'] ?? const []);
      likes.remove(userId);
      dislikes.remove(userId);
      if (isLike) {
        likes.add(userId);
      } else {
        dislikes.add(userId);
      }
      tx.update(ref, {
        'likes': likes,
        'dislikes': dislikes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
