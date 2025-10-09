import 'package:flutter/material.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/services/pet_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetView extends StatefulWidget {
  final Pet pet;
  const PetView({super.key, required this.pet});

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  late Pet _pet;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _nameController.text = _pet.name;
    _breedController.text = _pet.breed;
    _ageController.text = _pet.age.toString();
  }

  Future<void> _updatePet() async {
    if (_uid == null) return;
    if (!_formKey.currentState!.validate()) return;

    await PetService(_uid!).updatePet(
      _pet.id,
      name: _nameController.text,
      breed: _breedController.text,
      age: int.tryParse(_ageController.text),
    );

    setState(() {
      _pet = Pet(
        id: _pet.id,
        name: _nameController.text,
        breed: _breedController.text,
        age: int.tryParse(_ageController.text) ?? _pet.age,
      );
    });

    Navigator.pop(context); // close the dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pet info updated')));
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pet Info'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter a name' : null,
                ),
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(labelText: 'Breed'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter a breed' : null,
                ),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter age' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _updatePet, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pet.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditDialog),
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
          ],
        ),
      ),
    );
  }
}
