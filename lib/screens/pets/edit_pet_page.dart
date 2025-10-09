import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/services/pet_service.dart';
import 'package:flutter_app/services/pet_service.dart';

class EditPetPage extends StatefulWidget {
  final Pet pet;
  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _colourCtrl;
  late final TextEditingController _preferencesCtrl;

  // Dropdown state
  late int? _selectedAge; // years
  late String? _selectedSize;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Options
  final List<int> _ageOptions = List<int>.generate(31, (i) => i); // 0..30
  final List<String> _sizeOptions = const [
    'Tiny,',
    'Small',
    'Medium',
    'Large',
    'Huge',
    'Gargantuan',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet.name);
    _breedCtrl = TextEditingController(text: widget.pet.breed);
    _weightCtrl = TextEditingController(text: widget.pet.weight.toString());
    _colourCtrl = TextEditingController(text: widget.pet.colour);
    _preferencesCtrl = TextEditingController(text: widget.pet.preferences);

    _selectedAge = widget.pet.age;
    _selectedSize = widget.pet.size.isNotEmpty ? widget.pet.size : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _weightCtrl.dispose();
    _colourCtrl.dispose();
    _preferencesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    final newName = _nameCtrl.text.trim();
    final newBreed = _breedCtrl.text.trim();
    final newAge = _selectedAge ?? widget.pet.age;
    final newSize = _selectedSize ?? widget.pet.size;
    final newWeight =
        double.tryParse(_weightCtrl.text.trim()) ?? widget.pet.weight;
    final newColour = _colourCtrl.text.trim();
    final newPreferences = _preferencesCtrl.text.trim();

    await PetService(_uid!).updatePet(
      widget.pet.id,
      name: newName,
      breed: newBreed,
      age: newAge,
      size: newSize,
      weight: newWeight,
      colour: newColour,
      preferences: newPreferences,
    );

    Navigator.pop(
      context,
      Pet(
        id: widget.pet.id,
        name: newName,
        breed: newBreed,
        age: newAge,
        size: newSize,
        weight: newWeight,
        colour: newColour,
        preferences: newPreferences,
      ),
    );
  }

  Future<void> _delete() async {
    if (_uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    // Ask for confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: const Text(
          'Are you sure you want to delete this pet? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PetService(_uid!).deletePet(widget.pet.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet deleted')));

      // Pop twice: Edit → PetView → PetList
      Navigator.pop(context); // pop EditPetPage
      Navigator.pop(context, 'deleted'); // pop PetView
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting pet: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breedCtrl,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a breed' : null,
              ),

              const SizedBox(height: 12),
              // AGE DROPDOWN
              DropdownButtonFormField<int>(
                initialValue: _selectedAge,
                items: _ageOptions
                    .map(
                      (a) => DropdownMenuItem<int>(value: a, child: Text('$a')),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedAge = val),
                decoration: const InputDecoration(
                  labelText: 'Age (years)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null ? 'Select age' : null,
              ),

              const SizedBox(height: 12),
              // SIZE DROPDOWN
              DropdownButtonFormField<String>(
                initialValue: _selectedSize,
                items: _sizeOptions
                    .map(
                      (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedSize = val),
                decoration: const InputDecoration(
                  labelText: 'Size',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null ? 'Select size' : null,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter weight' : null,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _colourCtrl,
                decoration: const InputDecoration(
                  labelText: 'Colour',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter colour' : null,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _preferencesCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Preferences',
                  hintText: 'Grooming sensitivities, notes, etc.',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save changes'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
