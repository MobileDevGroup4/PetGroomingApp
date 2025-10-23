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

  Future<String> addPet(
    String name,
    String breed,
    int age,
    String size,
    double? weight,
    String colour,
    String preferences,
  ) async {
    final ref = await _petsCol.add({
      'name': name,
      'breed': breed,
      'age': age,
      'size': size,
      'weight': weight,
      'colour': colour,
      'preferences': preferences,
      'createdAt': FieldValue.serverTimestamp(), // <—
    });
    return ref.id;
  }

  Future<void> updatePet(
    String id, {
    String? name,
    String? breed,
    int? age,
    String? size,
    double? weight,
    String? colour,
    String? preferences,
  }) {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (breed != null) data['breed'] = breed;
    if (size != null) data['size'] = size;
    if (weight != null) data['weight'] = weight;
    if (colour != null) data['colour'] = colour;
    if (preferences != null) data['preferences'] = preferences;
    if (age != null) data['age'] = age;
    return _petsCol.doc(id).update(data);
  }

  Future<void> deletePet(String id) => _petsCol.doc(id).delete();

 List<Pet> _fromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
  return snap.docs.map((doc) {
    final data = doc.data();

    final ageRaw = data['age'];
    final int age = (ageRaw is int)
        ? ageRaw
        : (ageRaw is num)
            ? ageRaw.toInt()
            : int.tryParse(ageRaw?.toString() ?? '') ?? 0;

    final weightRaw = data['weight'];
    final double weight = (weightRaw is double)
        ? weightRaw
        : (weightRaw is num)
    ? weightRaw.toDouble()        
    : double.tryParse(weightRaw?.toString() ?? '') ?? 0.0;

    return Pet(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      breed: (data['breed'] as String?) ?? '',
      size: (data['size'] as String?) ?? '',
      colour: (data['colour'] as String?) ?? '',
      preferences: (data['preferences'] as String?) ?? '',
      age: age,
      weight: weight,
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
