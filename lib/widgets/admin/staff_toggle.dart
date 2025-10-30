import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffToggle extends StatelessWidget {
  const StaffToggle({
    super.key,
    required this.docId,
    this.collection = 'users',
  });

  final String docId;
  final String collection;

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection(collection).doc(docId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: Icon(Icons.verified_user_outlined),
            title: Text('Staff'),
            subtitle: Text('Loading…'),
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const ListTile(
            leading: Icon(Icons.verified_user_outlined),
            title: Text('Staff'),
            subtitle: Text('User not found'),
          );
        }
        final data = snap.data!.data()!;
        final isStaff = (data['isStaff'] as bool?) ?? false;

        Future<void> toggle(bool value) async {
          try {
            await docRef.update({
              'isStaff': value,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Marked as staff' : 'Removed staff status',
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
            }
          }
        }

        return SwitchListTile.adaptive(
          value: isStaff,
          onChanged: toggle,
          title: const Text('Staff'),
          subtitle: const Text('Grant staff capabilities inside the app'),
          secondary: const Icon(Icons.verified_user_outlined),
          contentPadding: const EdgeInsets.only(left: 8, right: 12),
        );
      },
    );
  }
}
