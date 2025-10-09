import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/screens/pets/add_pet_page.dart';
import 'package:flutter_app/widgets/pet_list.dart';

class PetSection extends StatelessWidget {
  const PetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<List<Pet>>();

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
    return const PetList();
  }
}
