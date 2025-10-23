import 'package:flutter/material.dart';
import '../../../repositories/profiles_repository.dart';
import 'admin_profiles_page.dart';
import 'register_staff_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = const ProfilesRepository().streamProfiles(onlyStaff: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Register new staff',
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterStaffPage()),
              );
            },
          ),
        ],
      ),
      body: AdminProfilesPage(stream: stream, collection: 'profiles'),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Register staff'),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegisterStaffPage()));
        },
      ),
    );
  }
}
