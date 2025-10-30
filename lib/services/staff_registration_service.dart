import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

class StaffRegistrationService {
  static const _profilesCol = 'profiles';

  static Future<String> createAuthUserAndProfile({
    required String name,
    required String email,
    required String tempPassword,
    String? phone,
    String? address,
    bool isStaff = true,
    bool sendVerification = false,
    String languageCode = 'en',
  }) async {
    if (tempPassword.length < 6) {
      throw ArgumentError('Temporary password must be at least 6 characters.');
    }

    final secondary = await _getOrCreateSecondary();
    final auth2 = FirebaseAuth.instanceFor(app: secondary);

    try {
      auth2.setLanguageCode(languageCode);

      final cred = await auth2.createUserWithEmailAndPassword(
        email: email.trim(),
        password: tempPassword,
      );
      final uid = cred.user!.uid;
      final canonicalEmail = cred.user!.email ?? email.trim();

      await cred.user!.updateDisplayName(name.trim());

      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();
      await db.collection(_profilesCol).doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': canonicalEmail, // store the exact email Firebase has
        'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        'address': (address?.trim().isEmpty ?? true) ? null : address!.trim(),
        'photoUrl': null,
        'isStaff': isStaff,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (sendVerification && auth2.currentUser != null) {
        await auth2.currentUser!.sendEmailVerification();
      }

      return uid;
    } finally {
      try {
        await auth2.signOut();
      } catch (_) {}
      try {
        await secondary.delete();
      } catch (_) {}
    }
  }

  static Future<FirebaseApp> _getOrCreateSecondary() async {
    const name = 'admin-helper';
    try {
      return Firebase.app(name);
    } catch (_) {
      return Firebase.initializeApp(
        name: name,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }
}
