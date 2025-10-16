import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/widgets/pet_tile.dart';
import 'package:flutter_app/screens/pets/add_pet_page.dart';

class PetList extends StatelessWidget {
  const PetList({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<List<Pet>>();

    return Scaffold(
      appBar: AppBar(title: const Text("My Pets")),
      body: (pets.isEmpty)
          ? const Center(child: Text('No pets yet'))
          : ListView.builder(
              itemCount: pets.length,
              itemBuilder: (_, i) => PetTile(pet: pets[i]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPetPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
