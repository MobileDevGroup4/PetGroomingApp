import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/services/pet_service.dart';
import 'package:flutter_app/constants/pet_options.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/services/storage_service.dart';

class EditPetPage extends StatefulWidget {
  final Pet pet;
  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _colourCtrl;
  late final TextEditingController _preferencesCtrl;
  late int? _selectedAge;
  late String? _selectedSize;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  final List<int> _ageOptions = PetOptions.ageYears;
  final List<String> _sizeOptions = PetOptions.sizeLabels;

  final _picker = ImagePicker();
  final _fsStorage = FirestoreStorageService();
  Uint8List? _localPhotoBytes;

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

  Future<void> _pickPhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxHeight: 800,
      maxWidth: 800,
    );
    if (x == null) return;
    _localPhotoBytes = await x.readAsBytes();
    setState(() {});
  }

  Widget _photoSection(String uid, String petId) {
    return FutureBuilder<Uint8List?>(
      future: _fsStorage.loadPetImage(uid: uid, petId: petId),
      builder: (context, snap) {
        final display = _localPhotoBytes ?? snap.data;
        final img = (display != null) ? MemoryImage(display) : null;
        return Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: img,
                child: img == null ? const Icon(Icons.pets, size: 48) : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Change photo',
                  onPressed: _pickPhoto,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;

  final uid = _uid;
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not signed in')),
    );
    return;
  }

  final newName        = _nameCtrl.text.trim();
  final newBreed       = _breedCtrl.text.trim();
  final newAge         = _selectedAge ?? widget.pet.age;
  final newSize        = _selectedSize ?? widget.pet.size;
  final newWeight      = double.tryParse(_weightCtrl.text.trim()) ?? widget.pet.weight;
  final newColour      = _colourCtrl.text.trim();
  final newPreferences = _preferencesCtrl.text.trim();

  // 1) Met à jour les champs texte
  await PetService(uid).updatePet(
    widget.pet.id,
    name: newName,
    breed: newBreed,
    age: newAge,
    size: newSize,
    weight: newWeight,
    colour: newColour,
    preferences: newPreferences,
  );

  // 2) Upload la photo si l’utilisateur en a choisi une
  if (_localPhotoBytes != null) {
    try {
      await _fsStorage.savePetImage(
        uid: uid,
        petId: widget.pet.id,
        bytes: _localPhotoBytes!,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo save failed: $e')),
      );
      return; // on ne pop pas si l'upload échoue
    }
    _localPhotoBytes = null;
  }

  if (!mounted) return;

  // 3) Retourne le Pet mis à jour à l’écran précédent (un seul pop)
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Pet'),
        content: const Text(
          'Are you sure you want to delete this pet? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PetService(_uid!).deletePet(widget.pet.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet deleted')),
      );
      Navigator.pop(context); // EditPetPage
      Navigator.pop(context, 'deleted'); // PetView
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting pet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
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
              if (uid != null) _photoSection(uid, widget.pet.id),
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
              DropdownButtonFormField<int>(
                initialValue: _selectedAge,
                items: _ageOptions
                    .map((a) => DropdownMenuItem<int>(value: a, child: Text('$a')))
                    .toList(),
                onChanged: (val) => setState(() => _selectedAge = val),
                decoration: const InputDecoration(
                  labelText: 'Age (years)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null ? 'Select age' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSize,
                items: _sizeOptions
                    .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
