import 'package:cloud_firestore/cloud_firestore.dart';

const String userProfilesCollection = 'profiles';

class ProfilesRepository {
  const ProfilesRepository();

  Query<Map<String, dynamic>> baseQuery({required bool onlyStaff}) {
    final col = FirebaseFirestore.instance.collection(userProfilesCollection);
    if (onlyStaff) {
      // No orderBy to avoid composite index requirement
      return col.where('isStaff', isEqualTo: true).limit(200);
    }
    return col.orderBy('updatedAt', descending: true).limit(200);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamProfiles({
    required bool onlyStaff,
  }) {
    return baseQuery(onlyStaff: onlyStaff).snapshots();
  }

  Future<void> updateIsStaff({
    required String docId,
    required bool isStaff,
  }) async {
    await FirebaseFirestore.instance
        .collection(userProfilesCollection)
        .doc(docId)
        .update({
          'isStaff': isStaff,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
