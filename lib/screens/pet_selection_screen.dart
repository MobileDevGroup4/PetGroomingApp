import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/pet.dart';
import '../services/pet_service.dart';
import '../screens/pets/add_pet_page.dart';
import '../models/service.dart';
import '../models/package.dart';
import 'date_time_screen.dart';

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
      body: _pets.isEmpty
          ? _buildNoPetsView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select a pet for $itemName',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _pets.length,
                    itemBuilder: (context, index) {
                      final pet = _pets[index];
                      final isSelected = _selectedPet?.id == pet.id;

                      return _buildPetTile(pet, isSelected, user.uid);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPetTile(Pet pet, bool isSelected, String userId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      child: ListTile(
        leading: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('petAvatars')
              .doc('${userId}_${pet.id}')
              .snapshots(),
          builder: (context, snap) {
            Uint8List? bytes;
            final data = snap.data?.data();
            final raw = data?['data'];
            if (raw is Uint8List) bytes = raw;
            if (raw is List) {
              bytes = Uint8List.fromList(raw.cast<int>());
            }

            final img = (bytes != null && bytes.isNotEmpty)
                ? MemoryImage(bytes)
                : null;

            return CircleAvatar(
              radius: 24,
              backgroundImage: img,
              backgroundColor: Colors.blue.shade100,
              child: img == null
                  ? Icon(Icons.pets, color: Colors.blue.shade700, size: 24)
                  : null,
            );
          },
        ),
        title: Text(
          pet.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text('${pet.breed} • ${pet.age} years old • ${pet.size}'),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.green.shade600)
            : null,
        selected: isSelected,
        selectedTileColor: Colors.blue.shade50,
        onTap: () {
          setState(() {
            _selectedPet = pet;
          });
        },
      ),
    );
  }

  Widget _buildNoPetsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No pets found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You need to add a pet before booking an appointment.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPetPage()),
                ).then((_) => _loadPets());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
            ),
          ],
        ),
      ),
    );
  }
}
