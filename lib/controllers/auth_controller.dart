import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  User? get currentUser => _authService.currentUser;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _authService.signInWithEmailAndPassword(email, password);
  }

  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _authService.registerWithEmailAndPassword(email, password);
  }

  Future<UserCredential?> signInWithGoogle() {
    return _authService.signInWithGoogle();
  }

  Future<void> signOut() {
    return _authService.signOut();
  }
}
