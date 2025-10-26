import 'package:flutter/material.dart';
import 'dart:typed_data';

Widget buildProfileAvatar({
  required String name,
  String? imageUrl,
  Uint8List? imageBytes,
  required bool isEditing,
  required VoidCallback onPickImage,
  required Color primaryColor,
}) {
  return Stack(
    children: [
      CircleAvatar(
        radius: 60,
        backgroundColor: primaryColor.withOpacity(0.2),
        backgroundImage: imageUrl != null
            ? NetworkImage(imageUrl)
            : (imageBytes != null ? MemoryImage(imageBytes) : null) as ImageProvider<Object>?,
        child: (imageUrl == null && imageBytes == null)
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryColor),
              )
            : null,
      ),
      if (isEditing)
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: primaryColor,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              onPressed: onPickImage,
            ),
          ),
        ),
    ],
  );
}

Widget buildStaffBadge(Color primaryColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: primaryColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, size: 16, color: primaryColor),
        const SizedBox(width: 4),
        Text('Staff Member', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget buildEditSaveButton({
  required bool isEditing,
  required bool isLoading,
  required Color primaryColor,
  required VoidCallback onPressed,
}) {
  return ElevatedButton.icon(
    onPressed: isLoading ? null : onPressed,
    icon: Icon(isEditing ? Icons.save : Icons.edit),
    label: Text(isEditing ? 'Save Profile' : 'Edit Profile'),
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    ),
  );
}

Widget buildInfoCard({
  required String title,
  required IconData icon,
  required List<Widget> children,
  required Color primaryColor,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(height: 24),
        ...children,
      ],
    ),
  );
}

Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required bool enabled,
  int maxLines = 1,
  String? hint,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    enabled: enabled,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: !enabled,
      fillColor: enabled ? null : Colors.grey.shade100,
    ),
  );
}
