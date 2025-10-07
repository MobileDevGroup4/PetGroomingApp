import 'package:flutter/material.dart';
import 'package:flutter_app/models/pet.dart';

class PetView extends StatelessWidget {
  final Pet pet;
  const PetView({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pet.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/dog.png'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Name: ${pet.name}",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              "Breed: ${pet.breed}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "Age: ${pet.age}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
