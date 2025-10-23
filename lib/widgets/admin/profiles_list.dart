import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile_tile.dart';

class ProfilesList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String search;
  final String collection;

  const ProfilesList({
    super.key,
    required this.stream,
    required this.search,
    this.collection = 'users',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          final e = snap.error;
          return Center(child: Text('Failed to load profiles\n$e'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            snap.data?.docs.toList() ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          docs = docs.where((d) {
            final m = d.data();
            final name = (m['name'] as String?)?.toLowerCase() ?? '';
            final email = (m['email'] as String?)?.toLowerCase() ?? '';
            return name.contains(q) || email.contains(q);
          }).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text('No profiles found'));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final d = docs[i];
            final data = d.data();
            final docId = d.id;
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
