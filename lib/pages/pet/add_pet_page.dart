import 'package:flutter/material.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/services/pet_service.dart';

class AddPetPage extends StatefulWidget {
  @override
  _AddPetPageState createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  PetService petService = PetService();
  String _name = '';
  String _breed = '';
  int _age = 0;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      //final newPet = Pet(name: _name, breed: _breed, age: _age);
      //Navigator.pop(context, newPet);
      petService.addPet(_name, _breed, _age);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add New Pet")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Pet name"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a name" : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Pet breed"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a breed" : null,
                onSaved: (value) => _breed = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Pet age"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter age";
                  }
                  if (int.tryParse(value) == null) {
                    return "Age must be a number";
                  }
                  return null;
                },
                onSaved: (value) => _age = int.parse(value!),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: Text("Add")),
            ],
          ),
        ),
      ),
    );
  }
}
