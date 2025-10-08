import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package.dart';

class PackagesRepository {
  final _col = FirebaseFirestore.instance.collection('packages');

  Stream<List<Package>> streamPackages() {
    return _col.orderBy('order').snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        return Package(
          id: d.id,
          name: (data['name'] ?? '') as String,
          shortDescription: (data['shortDescription'] ?? '') as String,
          services: List<String>.from(data['services'] ?? const []),
          priceLabel: (data['priceLabel'] ?? '') as String,
          badge: (data['badge'] ?? '') as String,
          durationMinutes: (data['durationMinutes'] as num? ?? 0).toInt(),
        );
      }).toList();
    });
  }
}
