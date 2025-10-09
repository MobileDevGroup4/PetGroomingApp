import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _col = FirebaseFirestore.instance.collection('profiles');

  Future<UserProfile> fetch(String uid, {String? email}) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) {
      final profile = UserProfile.empty(uid: uid, email: email);
      await _col.doc(uid).set(profile.toMap());
      return profile;
    }
    return UserProfile.fromMap(doc.data()!);
  }

  Future<void> save(UserProfile profile) async {
    await _col.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }
}