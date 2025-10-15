import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileSvc = ProfileService();
  final _fsStorage = FirestoreStorageService();
  final _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  TextEditingController? _nameCtrl;
  TextEditingController? _phoneCtrl;
  TextEditingController? _addressCtrl;

  late Future<UserProfile> _profileFuture;

  bool _saving = false;
  Uint8List? _avatarBytes;     
  Uint8List? _localAvatarBytes; 

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _profileFuture = _profileSvc.getProfile(uid!);
    _loadAvatar(uid);
  }

  @override
  void dispose() {
    _nameCtrl?.dispose();
    _phoneCtrl?.dispose();
    _addressCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar(String uid) async {
    final bytes = await _fsStorage.loadProfileImage(uid: uid);
    if (!mounted) return;
    setState(() => _avatarBytes = bytes);
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() => _localAvatarBytes = bytes);
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'Name is too short';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return 'Enter a valid phone number';
    return null;
  }

  String? _validateAddress(String? v) {
    if (v == null || v.trim().isEmpty) return 'Address is required';
    if (v.trim().length < 5) return 'Address is too short';
    return null;
  }

  Future<void> _save(UserProfile existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      // 1) Save avatar bytes to Firestore if user picked a new one
      if (_localAvatarBytes != null) {
        await _fsStorage.saveProfileImage(uid: existing.uid, bytes: _localAvatarBytes!);
        _avatarBytes = _localAvatarBytes;
        _localAvatarBytes = null;
      }

      // 2) Save text fields to Profile document
      final updated = existing.copyWith(
        name: _nameCtrl!.text.trim(),
        phone: _phoneCtrl!.text.trim(),
        address: _addressCtrl!.text.trim(),
        
      );
      await _profileSvc.updateProfile(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildAvatar() {
    final display = _localAvatarBytes ?? _avatarBytes;
    final img = display != null ? MemoryImage(display) : null;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: img,
            child: img == null ? const Icon(Icons.person, size: 48) : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: IconButton.filledTonal(
              tooltip: 'Change photo',
              onPressed: _pickImage,
              icon: const Icon(Icons.edit_outlined),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.greenAccent[50],
        actions: [
          FutureBuilder<UserProfile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final canSave = snapshot.hasData && !_saving;
              return IconButton(
                tooltip: 'Save',
                onPressed: canSave ? () => _save(snapshot.data!) : null,
                icon: _saving
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Profile not found.'));
          }

          final p = snapshot.data!;
          _nameCtrl ??= TextEditingController(text: p.name);
          _phoneCtrl ??= TextEditingController(text: p.phone);
          _addressCtrl ??= TextEditingController(text: p.address);

          return AbsorbPointer(
            absorbing: _saving,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    maxLines: 2,
                    validator: _validateAddress,
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _saving ? null : () => _save(p),
                    icon: const Icon(Icons.check),
                    label: _saving ? const Text('Saving...') : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
