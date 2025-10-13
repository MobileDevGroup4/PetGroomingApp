import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreStorageService {
  FirestoreStorageService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Document path: profileAvatars/{uid}
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('profileAvatars').doc(uid);

  /// Save small avatar bytes (keep well under 1 MB; recommended < 300 KB).
  Future<void> saveProfileImage({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (bytes.length > 900 * 1024) {
      throw Exception('Image too large (>900KB). Pick a smaller one.');
    }
    await _doc(uid).set({
      'data': bytes,                // Firestore Blob
      'contentType': contentType,   // optional
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Uint8List?> loadProfileImage({required String uid}) async {
  final snap = await _doc(uid).get();
  if (!snap.exists) return null;
  final data = snap.data();
  if (data == null) return null;

  final raw = data['data'];
  if (raw == null) return null;

  // Handle both Blob (Uint8List) and Array<int>
  if (raw is Uint8List) return raw;
  if (raw is List) {
    try {
      return Uint8List.fromList(raw.cast<int>());
    } catch (_) {
      // fallback: attempt manual int conversion
      return Uint8List.fromList(raw.map((e) => (e as num).toInt()).toList());
    }
  }
  return null;
}

  Future<void> deleteProfileImage({required String uid}) async {
    await _doc(uid).delete();
  }
}
