import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<UserProfile> get _col =>
      _db.collection('profiles').withConverter<UserProfile>(
        fromFirestore: (snap, _) => UserProfile.fromMap({
          ...?snap.data(),
          'uid': snap.id,
        }),
        toFirestore: (p, _) => p.toMap(),
      );

  Future<UserProfile> getProfile(String uid) async {
    final doc = await _col.doc(uid).get();
    if (doc.exists) return doc.data()!;
    final empty = UserProfile(uid: uid, name: '', phone: '', address: '', photoUrl: null);
    await _col.doc(uid).set(empty);
    return empty;
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _col.doc(uid).snapshots().map((s) => s.data());
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _col.doc(profile.uid).set(profile, SetOptions(merge: true));
    await _db.collection('profiles').doc(profile.uid).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
