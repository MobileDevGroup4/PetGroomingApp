// lib/services/storage_service.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreStorageService {
  FirestoreStorageService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('profileAvatars').doc(uid);

  Future<void> saveProfileImage({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (bytes.length > 900 * 1024) {
      throw Exception('Image too large (>900KB). Pick a smaller one.');
    }
    await _userDoc(uid).set({
      'data': bytes,
      'contentType': contentType,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Uint8List?> loadProfileImage({required String uid}) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    final raw = snap.data()?['data'];
    if (raw is Uint8List) return raw;                 // Blob -> Uint8List
    if (raw is List) return Uint8List.fromList(raw.cast<int>()); // Array<int>
    return null;
  }

  Future<void> deleteProfileImage({required String uid}) async {
    await _userDoc(uid).delete();
  }

  DocumentReference<Map<String, dynamic>> _petDoc(String uid, String petId) =>
      _db.collection('petAvatars').doc('${uid}_$petId');

  Future<void> savePetImage({
    required String uid,
    required String petId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (bytes.length > 900 * 1024) {
      throw Exception('Image too large (>900KB). Pick a smaller one.');
    }
    await _petDoc(uid, petId).set({
      'data': bytes,
      'contentType': contentType,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Uint8List?> loadPetImage({
    required String uid,
    required String petId,
  }) async {
    final snap = await _petDoc(uid, petId).get();
    if (!snap.exists) return null;
    final raw = snap.data()?['data'];
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return null;
  }

  Future<void> deletePetImage({
    required String uid,
    required String petId,
  }) async {
    await _petDoc(uid, petId).delete();
  }
}
