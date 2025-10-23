import 'package:flutter/material.dart';
import '../../repositories/profiles_repository.dart'; // adjust path if needed
import 'admin_profiles_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = const ProfilesRepository().streamProfiles(onlyStaff: false);

    return AdminProfilesPage(stream: stream, collection: 'profiles');
  }
}
