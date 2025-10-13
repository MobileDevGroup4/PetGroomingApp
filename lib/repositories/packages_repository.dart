import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package.dart';

class PackagesRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('packages');

  /// Streams packages (optionally only active ones) ordered by 'order'.
  /// Note: Make sure all docs have the 'order' field.
  /// If you get an error about missing 'order', either populate it or
  /// change the sorting to `.orderBy('name')`.
  Stream<List<Package>> streamPackages({bool? onlyActive}) {
  Query<Map<String, dynamic>> q = _col;

  if (onlyActive != null) {
    // signed out -> filter active only, NO orderBy (évite index composite)
    q = q.where('isActive', isEqualTo: onlyActive);
  } else {
    // signed in -> on garde le tri serveur existant
    q = q.orderBy('order');
  }

  return q.snapshots().map((snap) {
    final list = snap.docs.map((d) {
      final data = d.data();
      return Package(
        id: d.id,
        name: (data['name'] ?? '') as String,
        shortDescription: (data['shortDescription'] ?? '') as String,
        services: List<String>.from(data['services'] ?? const []),
        priceLabel: (data['priceLabel'] ?? '') as String,
        badge: (data['badge'] ?? '') as String,
        durationMinutes: (data['durationMinutes'] as num? ?? 0).toInt(),
        isActive: (data['isActive'] as bool?) ?? true,
      );
    }).toList();

    // si filtré, on trie côté client (ex: par name)
    if (onlyActive != null) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  });
}

  /// Toggle a package status (active/inactive) and stamp 'updatedAt'
  Future<void> setActive(String id, bool isActive) async {
    await _col.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// (Optional) Generic update helper for later edits (price/duration/text)
  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
