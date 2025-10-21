import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../screens/pets/add_pet_page.dart';
import 'date_time_screen.dart';
import '../models/service.dart';
import '../models/package.dart';

class PetSelectionScreen extends StatefulWidget {
  final Service? service;
  final Package? package;

  const PetSelectionScreen({super.key, this.service, this.package})
    : assert(
        service != null || package != null,
        'Either service or package must be provided',
      );

  @override
  State<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends State<PetSelectionScreen> {
  Pet? _selectedPet;
  List<Pet> _pets = [];
  bool _isLoading = true;

  String get itemName => widget.service?.name ?? widget.package?.name ?? '';

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final petService = PetService(user.uid);
      final pets = await petService.pets.first;
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Pet')),
        body: const Center(child: Text('Please log in to book appointments')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Pet')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Pet'),
        actions: [
          if (_selectedPet != null)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DateTimeScreen(
                      service: widget.service,
                      package: widget.package,
                      selectedPet: _selectedPet!,
                    ),
                  ),
                );
              },
              child: const Text('Next'),
            ),
        ],
      ),
      body: _pets.isEmpty ? _buildNoPetsWidget() : _buildPetsList(_pets),
    );
  }

  Widget _buildNoPetsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('You need to add a pet first to book $itemName'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPetPage()),
              );
              _loadPets(); // Reload pets after adding
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Pet'),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList(List<Pet> pets) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select a pet for $itemName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final isSelected = _selectedPet?.id == pet.id;

              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      pet.name.isNotEmpty ? pet.name[0].toUpperCase() : 'P',
                    ),
                  ),
                  title: Text(pet.name),
                  subtitle: Text(
                    '${pet.breed} • ${pet.age} years old • ${pet.size}',
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedPet = pet;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
