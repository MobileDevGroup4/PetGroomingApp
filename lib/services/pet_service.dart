import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/pet.dart';

class PetService {
  PetService(this.uid) : assert(uid.isNotEmpty);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _petsCol => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('pets');

  Future<void> addPet(String name, String breed, int age) async {
    await _petsCol.add({
      'name': name,
      'breed': breed,
      'age': age,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePet(String id, {String? name, String? breed, int? age}) {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (breed != null) data['breed'] = breed;
    if (age != null) data['age'] = age;
    return _petsCol.doc(id).update(data);
  }

  /*
  Future<void> updatePet(String id, {String? name, String? breed, int? age}) {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (breed != null) data['breed'] = breed;
    if (age != null) data['age'] = age;
    return _petsCol.doc(id).update(data);
  }
  */

  Future<void> deletePet(String id) => _petsCol.doc(id).delete();

  List<Pet> _fromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs.map((doc) {
      final data = doc.data();
      final ageRaw = data['age'];
      final age = (ageRaw is int) ? ageRaw : int.tryParse('${ageRaw}') ?? 0;

      return Pet(
        id: doc.id,
        name: (data['name'] as String?) ?? '',
        breed: (data['breed'] as String?) ?? '',
        age: age,
      );
    }).toList();
  }

  Stream<List<Pet>> get pets {
    return _petsCol
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(_fromSnapshot);
  }
}
