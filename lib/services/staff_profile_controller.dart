import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'storage_service.dart';

class StaffProfileController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirestoreStorageService();

  Future<Map<String, dynamic>?> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('profiles').doc(user.uid).get();
    return doc.data();
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('profiles').doc(user.uid).set({
      ...data,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    final user = _auth.currentUser;
    if (user == null) return null;

    final bytes = await pickedFile.readAsBytes();

    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('profiles/${user.uid}/$fileName');

      await ref.putData(bytes,
          firebase_storage.SettableMetadata(contentType: 'image/jpeg'));

      final downloadUrl = await ref.getDownloadURL();
      return {'url': downloadUrl, 'bytes': null};
    } catch (e) {
      await _storage.saveProfileImage(uid: user.uid, bytes: bytes);
      return {'url': null, 'bytes': bytes};
    }
  }
}
