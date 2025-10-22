import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'staff_toggle.dart';

class ProfileTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const ProfileTile({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final name = (d['name'] as String?)?.trim();
    final email = (d['email'] as String?)?.trim();
    final uid = (d['uid'] as String?) ?? '—';
    final isStaff = (d['isStaff'] as bool?) ?? false;

    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(
        name?.isNotEmpty == true
            ? name!
            : (email?.isNotEmpty == true ? email! : 'Unnamed user'),
      ),
      subtitle: Text(
        [if (email != null && email.isNotEmpty) email, 'UID: $uid'].join('\n'),
      ),
      trailing: StaffToggle(docId: doc.id, initialValue: isStaff),
    );
  }
}
