import 'package:flutter/material.dart';
import 'user_profile_page.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.docId,
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    this.collection = 'users',
  });

  final String docId;
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String collection;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty
            ? Text(
                _initials(name),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              )
            : null,
      ),
      title: Text(name.isEmpty ? '—' : name),
      subtitle: Text(email),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                UserProfilePage(docId: docId, collection: collection),
          ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts[1][0] : ''))
        .toUpperCase();
  }
}
