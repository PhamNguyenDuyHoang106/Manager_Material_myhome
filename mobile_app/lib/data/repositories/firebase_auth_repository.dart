import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _mapAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'Email không tồn tại',
      'wrong-password' => 'Mật khẩu không đúng',
      'invalid-email' => 'Email không hợp lệ',
      'invalid-credential' => 'Email hoặc mật khẩu không đúng',
      _ => 'Đăng nhập thất bại ($code)',
    };
  }
}
