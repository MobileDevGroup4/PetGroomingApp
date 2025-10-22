import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile_tile.dart';

class ProfilesList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String search;

  const ProfilesList({super.key, required this.stream, required this.search});

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

        var docs = snap.data?.docs ?? const [];
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
          itemBuilder: (_, i) => ProfileTile(doc: docs[i]),
        );
      },
    );
  }
}
