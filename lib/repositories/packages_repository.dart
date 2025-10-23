import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/package.dart';

class PackagesRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('packages');

  // --- helper local pour extraire un double du priceLabel ---
  double? _parsePriceLabelToDouble(String label) {
    final m = RegExp(r'([\d]+(?:[.,]\d+)?)').firstMatch(label);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }

  Stream<List<Package>> streamPackages({bool? onlyActive}) {
    Query<Map<String, dynamic>> q = _col;

    if (onlyActive != null) {
      q = q.where('isActive', isEqualTo: onlyActive);
    } else {
      q = q.orderBy('order');
    }

    return q.snapshots().map((snap) {
      final list = snap.docs.map((d) => Package.fromMap(d.id, d.data())).toList();
      if (onlyActive != null) list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<void> setActive(String id, bool isActive) async {
    await _col.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePackage(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> updatePackageFields(String id, Map<String, dynamic> data) {
    final clean = <String, dynamic>{};
    data.forEach((k, v) {
      if (v != null) clean[k] = v;
    });
    clean['updatedAt'] = FieldValue.serverTimestamp();
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
    final base = _parsePriceLabelToDouble(priceLabel);

    final doc = await _col.add({
      'name': name,
      'shortDescription': shortDescription,
      'services': services,
      'priceLabel': priceLabel,
      'basePrice': base,
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

  // ---- Promo helpers (avec date de fin optionnelle) ----
 Future<void> setDiscount(
  String id, {
  required int percent,
  DateTime? endAt,
}) async {
  final map = <String, dynamic>{
    'discountPercent': percent.clamp(0, 90),
  };
  if (endAt == null) {
    map['discountEndAt'] = FieldValue.delete();
  } else {
    map['discountEndAt'] = Timestamp.fromDate(endAt);
  }
  await updatePackageFields(id, map);
}

  Future<void> clearDiscount(String id) async {
  await updatePackageFields(id, {
    'discountPercent': FieldValue.delete(),
    'discountEndAt': FieldValue.delete(),
  });
}

}
