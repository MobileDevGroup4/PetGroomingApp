import 'package:flutter/material.dart';
import '../repositories/profiles_repository.dart';
import '../widgets/admin/profiles_list.dart';

class AdminProfilesPage extends StatefulWidget {
  const AdminProfilesPage({super.key});

  @override
  State<AdminProfilesPage> createState() => _AdminProfilesPageState();
}

class _AdminProfilesPageState extends State<AdminProfilesPage> {
  final _repo = const ProfilesRepository();
  String _search = '';
  bool _onlyStaff = false;

  @override
  Widget build(BuildContext context) {
    final stream = _repo.streamProfiles(onlyStaff: _onlyStaff);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - User Profiles'),
        actions: [
          Row(
            children: [
              const Text('Only staff'),
              Switch(
                value: _onlyStaff,
                onChanged: (v) => setState(() => _onlyStaff = v),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name or email…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: ProfilesList(stream: stream, search: _search),
          ),
        ],
      ),
    );
  }
}
