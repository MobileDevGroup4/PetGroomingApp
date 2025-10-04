import 'package:flutter_app/models/pet.dart';
import 'package:flutter/material.dart';

class PetTile extends StatelessWidget {
  final Pet pet;
  PetTile({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25.0,
            backgroundImage: AssetImage('assets/dog.png'),
          ),
          title: Text(pet.name),
          subtitle: Text('Hardcoded dog named ${pet.name}'),
          onTap: (() => ()),
        ),
      ),
    );
  }
}
