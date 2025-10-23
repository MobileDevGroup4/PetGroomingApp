import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/admin/profile_tile.dart';

class AdminProfilesPage extends StatelessWidget {
  const AdminProfilesPage({
    super.key,
    required this.stream,
    this.search = '',
    this.collection = 'users',
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String search;
  final String collection;

  @override
  Widget build(BuildContext context) {
    final q = search.trim().toLowerCase();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data?.docs ?? const [];
        final docs = all.where((doc) {
          final data = doc.data();
          final name = (data['name'] as String?)?.toLowerCase() ?? '';
          final email = (data['email'] as String?)?.toLowerCase() ?? '';
          return q.isEmpty || name.contains(q) || email.contains(q);
        }).toList();

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final docId = doc.id;
            final uid = (data['uid'] as String?) ?? docId;
            final name = (data['name'] as String?)?.trim() ?? '—';
            final email = (data['email'] as String?)?.trim() ?? '';
            final photoUrl = (data['photoUrl'] as String?) ?? '';

            return ProfileTile(
              docId: docId,
              uid: uid,
              name: name,
              email: email,
              photoUrl: photoUrl,
              collection: collection,
            );
          },
        );
      },
    );
  }
}
