import 'package:flutter/material.dart';
import 'package:flutter_app/services/pet_service.dart';

class AddPetPage extends StatefulWidget {
  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _petService = PetService();

  String _name = '', _breed = '';
  dynamic _age = 0;
  final List<int> _ageOptions = List.generate(32, (i) => i); // 0–31

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await _petService.addPet(_name, _breed, _age); // await!
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add pet: $e')));
      }
    }
  }

  InputDecoration _field(String label) => InputDecoration(labelText: label);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Add Pet")),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              decoration: _field("Name"),
              validator: (v) => v!.isEmpty ? "Enter name" : null,
              onSaved: (v) => _name = v!,
            ),
            TextFormField(
              decoration: _field("Breed"),
              validator: (v) => v!.isEmpty ? "Enter breed" : null,
              onSaved: (v) => _breed = v!,
            ),
            DropdownButtonFormField<int>(
              decoration: _field("Age"),
              initialValue: _age,
              items: _ageOptions
                  .map(
                    (age) => DropdownMenuItem(value: age, child: Text('$age')),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _age = v),
              validator: (v) => v == null ? "Select age" : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: const Text("Add Pet")),
          ],
        ),
      ),
    ),
  );
}
