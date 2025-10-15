import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/screens/pets/add_pet_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter_app/screens/pets/pet_view.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetSection extends StatelessWidget {
  const PetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<List<Pet>>();
    final uid = FirebaseAuth.instance.currentUser?.uid;    
    final storage = FirestoreStorageService(); 

    if (pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No pets yet'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPetPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
            ),
          ],
        ),
      );
    }

    // Minimal change: just reuse your existing PetList widget
    return Stack(
      children: [
        ListView.separated(
          itemCount: pets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pet = pets[index];

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PetView(pet: pet)),
                  );
                },

                // Load avatar bytes from Firestore (petAvatars/{uid}_{petId})
                leading: (uid == null)
                  ? const CircleAvatar(radius: 24, child: Icon(Icons.pets))
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('petAvatars')
                          .doc('${uid}_${pet.id}')
                          .snapshots(),
                      builder: (context, snap) {
                        Uint8List? bytes;
                        final data = snap.data?.data();
                        final raw = data?['data'];
                        if (raw is Uint8List) bytes = raw;
                        if (raw is List) bytes = Uint8List.fromList(raw.cast<int>());

                        final img = (bytes != null && bytes.isNotEmpty) ? MemoryImage(bytes) : null;
                        return CircleAvatar(
                          radius: 24,
                          backgroundImage: img,
                          child: img == null ? const Icon(Icons.pets) : null,
                        );
                      },
                    ),

                title: Text(
                  pet.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text('Breed: ${pet.breed}, Age: ${pet.age}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),

        // Keep your UX: quick add button (optional but convenient)
        Positioned(
          right: 8,
          bottom: 8,
          child: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPetPage()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}