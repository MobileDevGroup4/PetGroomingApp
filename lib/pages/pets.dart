import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/pages/pet_tile.dart';

class PetList extends StatefulWidget {
  @override
  _PetListState createState() => _PetListState();
}

class _PetListState extends State<PetList> {
  @override
  Widget build(BuildContext context) {
    //final pets = Provider.of<List<Pet>>(context) ?? [];
    final pets = [];
    pets.add(new Pet(name: 'Korppu'));
    pets.add(new Pet(name: 'Musti'));
    pets.add(new Pet(name: 'Aatu'));

    return ListView.builder(
      itemCount: pets.length,
      itemBuilder: (context, index) {
        return PetTile(pet: pets[index]);
      },
    );
  }
}
