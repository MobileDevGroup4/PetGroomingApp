import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String breed;
  final int age;
  final String size;
  final String colour;
  final double weight;
  final String preferences;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.size,
    required this.colour,
    required this.weight,
    required this.preferences,
  });

  factory Pet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      size: data['size'] ?? '',
      colour: data['colour'] ?? '',
      weight: data['weight'] ?? 0.0,
      preferences: data['preferences'] ?? '',
    );
  }
}
