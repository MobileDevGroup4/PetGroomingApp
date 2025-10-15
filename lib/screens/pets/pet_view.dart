import 'package:flutter/material.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/screens/pets/edit_pet_page.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetView extends StatefulWidget {
  final Pet pet;
  const PetView({super.key, required this.pet});

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  late Pet _pet;
  final _fsStorage = FirestoreStorageService();

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  Future<void> _openEdit() async {
  final updated = await Navigator.push<Pet>(
    context,
    MaterialPageRoute(builder: (_) => EditPetPage(pet: _pet)),
  );

  if (!mounted) return; 

  if (updated != null) {
    setState(() => _pet = updated);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Pet updated')));
  }
}


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(_pet.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _openEdit),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: uid == null
            ? const Center(child: Text('Not signed in'))        
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('petAvatars')
                            .doc('${uid}_${_pet.id}') // <-- use _pet.id here
                            .snapshots(),
                        builder: (context, snap) {
                          Uint8List? bytes;
                          final data = snap.data?.data();
                          final raw = data?['data'];
                          if (raw is Uint8List) bytes = raw;
                          if (raw is List) bytes = Uint8List.fromList(raw.cast<int>());

                          final img = (bytes != null && bytes.isNotEmpty)
                              ? MemoryImage(bytes)
                              : null;

                          return CircleAvatar(
                            radius: 40,
                            backgroundImage: img,
                            child: img == null ? const Icon(Icons.pets, size: 40) : null,
                          );
                        },
                      ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${_pet.name}",
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text("Breed: ${_pet.breed}",
                            style: Theme.of(context).textTheme.bodyLarge),
                        Text("Age: ${_pet.age}",
                            style: Theme.of(context).textTheme.bodyLarge),
                        Text("Size: ${_pet.size}",
                            style: Theme.of(context).textTheme.bodyLarge),
                        Text("Colour: ${_pet.colour}",
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text("Preferences: ${_pet.preferences}",
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
        ),
      ),
    );
  }
}
