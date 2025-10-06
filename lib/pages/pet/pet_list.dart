// pet_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/pages/pet/pet_tile.dart';
import 'package:flutter_app/pages/pet/add_pet_page.dart';
import 'package:flutter_app/services/pet_service.dart';
import 'package:provider/provider.dart';

class PetList extends StatefulWidget {
  @override
  _PetListState createState() => _PetListState();
}

class _PetListState extends State<PetList> {
  @override
  Widget build(BuildContext context) {
    final pets = Provider.of<List<Pet>>(context) ?? [];

    return ListView.builder(
      itemCount: pets.length,
      itemBuilder: (context, index) {
        return PetTile(pet: pets[index]);
      },
    );
  }
}

/*
class _PetListState extends State<PetList> {
  final pets = Provider.of<List<Pet>>(context) ?? [];

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
        tooltip: 'Add a new pet',
        child: Icon(Icons.add),
      ),
    );
  }
}
*/
