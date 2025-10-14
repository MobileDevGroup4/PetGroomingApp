import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes (logged in/out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register new user with email and password
  Future<UserCredential?> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.sendEmailVerification();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Login with email and password
  Future<UserCredential?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result; // <-- return the credential
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// One-off check: is the current user an admin? (forces token refresh)
  Future<bool> isAdmin() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    final t = await u.getIdTokenResult(true); // force refresh
    return (t.claims?['admin'] as bool?) ?? false;
  }

  /// Optional: call once after you change roles server-side
  Future<void> refreshClaims() async {
    final u = _auth.currentUser;
    if (u != null) {
      await u.getIdToken(true);
    }
  }

  /// Reactive: emits true/false when the user's token changes (no forced refresh)
  Stream<bool> get adminRoleChanges async* {
    await for (final u in _auth.idTokenChanges()) {
      if (u == null) {
        yield false;
      } else {
        final t = await u.getIdTokenResult();
        yield (t.claims?['admin'] as bool?) ?? false;
      }
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Convert Firebase errors to user-friendly messages
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'An error occurred. Please try again';
    }
  }
}
