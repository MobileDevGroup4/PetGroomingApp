import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package.dart';

class PackagesRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('packages');

  Stream<List<Package>> streamPackages({bool? onlyActive}) {
    Query<Map<String, dynamic>> q = _col;

    if (onlyActive != null) {
      q = q.where('isActive', isEqualTo: onlyActive);
    } else {
      q = q.orderBy('order');
    }

    return q.snapshots().map((snap) {
      final List<Package> list = snap.docs.map((d) {
        final data = d.data();
        return Package(
          id: d.id,
          name: (data['name'] ?? '') as String,
          shortDescription: (data['shortDescription'] ?? '') as String,
          services: List<String>.from(data['services'] ?? const []),
          priceLabel: (data['priceLabel'] ?? '') as String,
          badge: (data['badge'] ?? '') as String,
          durationMinutes: (data['durationMinutes'] as num? ?? 0).toInt(),
          highlights: List<String>.from(data['highlights'] ?? const []),
          isActive: (data['isActive'] as bool?) ?? true,
        );
      }).toList();

      if (onlyActive != null) {
        list.sort((a, b) => a.name.compareTo(b.name));
      }
      return list;
    });
  }

  Future<void> setActive(String id, bool isActive) async {
    await _col.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  /// Delete a package document permanently
Future<void> deletePackage(String id) async {
  await _col.doc(id).delete();
}


  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePackageFields(String id, Map<String, dynamic> data) {
    final clean = <String, dynamic>{};
    data.forEach((k, v) {
      if (v != null) clean[k] = v;
    });
    return _col.doc(id).update(clean);
  }

  Future<String> createPackage({
    required String name,
    required String shortDescription,
    required List<String> services,
    required String priceLabel,
    String badge = '',
    required int durationMinutes,
    List<String> highlights = const [],
    bool visible = true,
  }) async {
    final doc = await _col.add({
      'name': name,
      'shortDescription': shortDescription,
      'services': services,
      'priceLabel': priceLabel,
      'badge': badge,
      'durationMinutes': durationMinutes,
      'highlights': highlights,
      'visible': visible,
      'isActive': visible,
      'order': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}
