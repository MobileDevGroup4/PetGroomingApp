import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _colour = '';
  String _preferences = '';
  String? _size;
  double? _weight;
  int? _age;

  final List<int> _ageOptions = List.generate(32, (i) => i);
  final List<String> _sizeOptions = [
    'Tiny',
    'Small',
    'Medium',
    'Large',
    'Huge',
    'Gargantuan',
  ];

  InputDecoration _field(String label) => InputDecoration(labelText: label);

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
      await PetService(
        uid,
      ).addPet(_name, _breed, _age!, _size!, _weight!, _colour, _preferences);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add pet: $e')));
    }
  }

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
                    (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              TextFormField(
                decoration: _field('Breed'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter breed' : null,
                onSaved: (v) => _breed = v!.trim(),
              ),
              DropdownButtonFormField<int>(
                decoration: _field('Age'),
                initialValue: _age,
                items: _ageOptions
                    .map(
                      (age) =>
                          DropdownMenuItem(value: age, child: Text('$age')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _age = v),
                onSaved: (v) => _age = v,
                validator: (v) => v == null ? 'Select age' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: _field('Size'),
                initialValue: _size,
                items: _sizeOptions
                    .map(
                      (size) =>
                          DropdownMenuItem(value: size, child: Text(size)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _size = v),
                onSaved: (v) => _size = v,
                validator: (v) => v == null ? 'Select size' : null,
              ),
              TextFormField(
                decoration: _field('Weight (kg)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\-]')),
                ],
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Enter weight';
                  final parsed = double.tryParse(s.replaceAll(',', '.'));
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed <= 0) return 'Weight must be > 0';
                  return null;
                },
                onSaved: (v) =>
                    _weight = double.tryParse((v ?? '').replaceAll(',', '.')),
              ),
              TextFormField(
                decoration: _field('Colour'),
                onSaved: (v) => _colour = (v ?? '').trim(),
              ),
              TextFormField(
                decoration: _field('Preferences'),
                maxLines: 3,
                onSaved: (v) => _preferences = (v ?? '').trim(),
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
