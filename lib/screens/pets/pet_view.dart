import 'package:flutter/material.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/screens/pets/edit_pet_page.dart';

class PetView extends StatefulWidget {
  final Pet pet;
  const PetView({super.key, required this.pet});

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  late Pet _pet;

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_pet.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _openEdit),
        ],
      ),
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
              "Name: ${_pet.name}",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              "Breed: ${_pet.breed}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "Age: ${_pet.age}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "Age: ${_pet.size}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "Colour: ${_pet.colour}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "Preferences: ${_pet.preferences}",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
