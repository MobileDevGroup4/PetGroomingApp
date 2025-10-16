import 'package:flutter/material.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/screens/pets/pet_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetTile extends StatelessWidget {
  final Pet pet;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  PetTile({super.key, required this.pet});

  void _navigateToPetView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PetView(pet: pet)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: ListTile(
          leading: const CircleAvatar(
            radius: 25.0,
            backgroundImage: AssetImage('assets/dog.png'),
          ),
          title: Text(pet.name),
          subtitle: Text('Breed: ${pet.breed}, Age: ${pet.age}'),
          onTap: () => _navigateToPetView(context),
          /*
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deletePet(context),
          ),
          */
        ),
      ),
    );
  }
}
