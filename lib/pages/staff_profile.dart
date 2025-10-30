import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../services/storage_service.dart';

import '../widgets/staff_profile_widgets.dart';

class StaffProfile extends StatefulWidget {
  const StaffProfile({super.key});

  @override
  State<StaffProfile> createState() => _StaffProfileState();
}

class _StaffProfileState extends State<StaffProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _experienceController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  Uint8List? _profileImageBytes;
  final FirestoreStorageService _fsStorage = FirestoreStorageService();

  final Color primaryPurple = const Color(0xFF6C63FF);
  final Color lightPurpleBackground = const Color(0xFFFAF4FA);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _specialtiesController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('profiles').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _specialtiesController.text = data['specialties'] ?? '';
          _experienceController.text = data['experience'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _profileImageUrl = data['profileImage'];
        });
        if (_profileImageUrl == null) {
          final bytes = await _fsStorage.loadProfileImage(uid: user.uid);
          if (bytes != null) setState(() => _profileImageBytes = bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('profiles').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'specialties': _specialtiesController.text.trim(),
        'experience': _experienceController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImage': _profileImageUrl,
        'isStaff': true,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to upload a profile image.'),
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      final bytes = await pickedFile.readAsBytes();

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('profiles')
          .child(user.uid)
          .child(fileName);

      final uploadTask = storageRef.putData(
        bytes,
        firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _profileImageBytes = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image uploaded'),
            backgroundColor: primaryPurple,
          ),
        );
      }
    } catch (e) {
      try {
        final bytes = await pickedFile.readAsBytes();
        await _fsStorage.saveProfileImage(uid: user.uid, bytes: bytes);
        if (mounted) {
          setState(() {
            _profileImageBytes = bytes;
            _profileImageUrl = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile image saved'),
              backgroundColor: primaryPurple,
            ),
          );
        }
      } catch (e2) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: $e / $e2')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: lightPurpleBackground,
      body: user == null
          ? const Center(child: Text('Please log in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    buildProfileAvatar(
                      name: _nameController.text,
                      imageUrl: _profileImageUrl,
                      imageBytes: _profileImageBytes,
                      isEditing: _isEditing,
                      onPickImage: _pickImage,
                      primaryColor: primaryPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isEmpty
                          ? 'Staff Member'
                          : _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildStaffBadge(primaryPurple),
                    const SizedBox(height: 24),
                    buildEditSaveButton(
                      isEditing: _isEditing,
                      isLoading: _isLoading,
                      primaryColor: primaryPurple,
                      onPressed: () {
                        if (_isEditing) {
                          _saveProfile();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                    ),
                    if (_isEditing)
                      TextButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _loadProfile();
                        },
                        child: const Text('Cancel'),
                      ),
                    const SizedBox(height: 24),
                    buildInfoCard(
                      title: 'Personal Information',
                      icon: Icons.person,
                      children: [
                        buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.badge,
                          enabled: _isEditing,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                      primaryColor: primaryPurple,
                    ),
                    const SizedBox(height: 16),
                    buildInfoCard(
                      title: 'Professional Details',
                      icon: Icons.work,
                      children: [
                        buildTextField(
                          controller: _bioController,
                          label: 'Bio',
                          icon: Icons.info,
                          enabled: _isEditing,
                          maxLines: 3,
                          hint: 'Tell us about yourself...',
                        ),
                        const SizedBox(height: 16),
                        buildTextField(
                          controller: _specialtiesController,
                          label: 'Specialties',
                          icon: Icons.star,
                          enabled: _isEditing,
                          hint: 'e.g., Dog grooming, Cat care, Nail trimming',
                        ),
                        const SizedBox(height: 16),
                        buildTextField(
                          controller: _experienceController,
                          label: 'Experience',
                          icon: Icons.timeline,
                          enabled: _isEditing,
                          hint: 'e.g., 5 years in pet grooming',
                        ),
                      ],
                      primaryColor: primaryPurple,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
