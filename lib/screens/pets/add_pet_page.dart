import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/pet_service.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _breed = '';
  int? _age; // <- make it nullable int
  final List<int> _ageOptions = List.generate(32, (i) => i); // 0–31

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add pets')),
      );
      return;
    }

    try {
      await PetService(uid).addPet(_name, _breed, _age!);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add pet: $e')));
    }
  }

  InputDecoration _field(String label) => InputDecoration(labelText: label);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: _field('Name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter name' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              TextFormField(
                decoration: _field('Breed'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter breed' : null,
                onSaved: (v) => _breed = v!.trim(),
              ),
              DropdownButtonFormField<int>(
                decoration: _field('Age'),
                value: _age, // start as null so user picks
                items: _ageOptions
                    .map(
                      (age) =>
                          DropdownMenuItem(value: age, child: Text('$age')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _age = v),
                validator: (v) => v == null ? 'Select age' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('Add Pet')),
            ],
          ),
        ),
      ),
    );
  }
}
