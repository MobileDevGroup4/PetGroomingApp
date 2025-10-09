import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final int duration;
  final double price;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
});

  // A factory constructor to create a Service from a Firestore document.
  factory Service.fromFirestore(DocumentSnapshot doc) {
    // Cast the data to a Map, or an empty map if it's null.
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Service(
      id: doc.id,
      name: data['s-name'] ?? 'No Name',
      description: data['s-description'] as String? ?? 'No Description',
      // Ensure duration is treated as an integer.
      duration: (data['s-duration'] as num?)?.toInt() ?? 0,
      // Ensure duration is treated as a double.
      price: (data['s-price'] as num?) ?.toDouble() ?? 0.0,
    );

  }
}