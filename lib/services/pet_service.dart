import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/pet.dart';

class PetService {
  final _db = FirebaseFirestore.instance;
  final CollectionReference _petCollection = FirebaseFirestore.instance
      .collection('pets');

  Future<void> addPet(String name, String breed, int age) async {
    await _petCollection.add({'name': name, 'breed': breed, 'age': age});
  }

  List<Pet> _petListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      //print(doc.data);
      return Pet(
        name: doc['name'] ?? '',
        breed: doc['breed'] ?? '',
        age: doc['age'] ?? '0',
      );
    }).toList();
  }

  Stream<List<Pet>> get pets {
    return _petCollection.snapshots().map(_petListFromSnapshot);
  }
}
