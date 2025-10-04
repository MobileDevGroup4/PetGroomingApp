// pet_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/pages/pet/pet_tile.dart';
import 'package:flutter_app/pages/add_pet_page.dart';

class PetList extends StatefulWidget {
  @override
  _PetListState createState() => _PetListState();
}

class _PetListState extends State<PetList> {
  final List<Pet> pets = [
    Pet(name: 'Korppu', breed: 'Terrier', age: 34),
    Pet(name: 'Riku', breed: 'Wookie', age: 1),
    Pet(name: 'Jesse', breed: 'Matt Damon', age: 98),
  ];

  Future<void> _navigateToAddPet() async {
    final newPet = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPetPage()),
    );

    if (newPet != null && newPet is Pet) {
      setState(() {
        pets.add(newPet);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Pets")),
      body: ListView.builder(
        itemCount: pets.length,
        itemBuilder: (context, index) {
          return PetTile(pet: pets[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPet,
        child: Icon(Icons.add),
        tooltip: 'Add a new pet',
      ),
    );
  }
}
