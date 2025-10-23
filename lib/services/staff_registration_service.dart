// lib/services/staff_registration_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

class StaffRegistrationService {
  static const _profilesCol = 'profiles';

  /// Creates an Auth user with a REQUIRED temporary password
  /// and seeds profiles/{uid} with isStaff: true (baseline).
  static Future<String> createAuthUserAndProfile({
    required String name,
    required String email,
    required String tempPassword, // <-- REQUIRED now
    String? phone,
    String? address,
    bool isStaff = true,
  }) async {
    // Basic guard
    if (tempPassword.length < 6) {
      throw ArgumentError('Temporary password must be at least 6 characters.');
    }

    final secondary = await _getOrCreateSecondary();
    final auth2 = FirebaseAuth.instanceFor(app: secondary);

    try {
      // 1) Create the new auth user on the secondary app
      final cred = await auth2.createUserWithEmailAndPassword(
        email: email.trim(),
        password: tempPassword,
      );
      final uid = cred.user!.uid;

      // 2) Seed/Upsert the profile doc with isStaff: true baseline
      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();
      await db.collection(_profilesCol).doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        'address': (address?.trim().isEmpty ?? true) ? null : address!.trim(),
        'photoUrl': null,
        'isStaff': isStaff,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      return uid;
    } finally {
      // 3) Clean up the secondary session/app
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
