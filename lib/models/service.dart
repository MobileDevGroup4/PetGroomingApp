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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      // Ensure duration is treated as an integer.
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      // Ensure duration is treated as a double.
      price: (data['price'] as num?) ?.toDouble() ?? 0.00,
    );

  }
}