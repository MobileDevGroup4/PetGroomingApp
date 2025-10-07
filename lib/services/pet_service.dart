import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/pet.dart';

class PetService {
  final CollectionReference<Map<String, dynamic>> _petCollection =
      FirebaseFirestore.instance.collection('pets');

  Future<void> addPet(String name, String breed, int age) async {
    await _petCollection.add({
      'name': name,
      'breed': breed,
      'age': age,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  List<Pet> _petListFromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final ageRaw = data['age'];
      final age = (ageRaw is int)
          ? ageRaw
          : int.tryParse(ageRaw?.toString() ?? '0') ?? 0;

      return Pet(
        // if your Pet has id field, pass doc.id
        name: (data['name'] as String?) ?? '',
        breed: (data['breed'] as String?) ?? '',
        age: age,
      );
    }).toList();
  }

  Stream<List<Pet>> get pets {
    return _petCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(_petListFromSnapshot);
  }
}
