import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/comment_service.dart';

class CommentController {
  final CommentService _service;
  final FirebaseAuth _auth;

  CommentController({
    CommentService? service,
    FirebaseAuth? auth,
  })  : _service = service ?? CommentService(),
        _auth = auth ?? FirebaseAuth.instance;

  Stream<QuerySnapshot> streamComments(String animalId) => _service.streamComments(animalId);

  Future<void> addComment({
    required String animalId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('require_login');
    if (text.trim().isEmpty) return;
    await _service.addComment(animalId: animalId, text: text.trim());
  }

  Future<void> vote({
    required String animalId,
    required String commentId,
    required bool isLike,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('require_login');
    await _service.vote(animalId: animalId, commentId: commentId, isLike: isLike);
  }
}
