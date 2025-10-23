import 'package:flutter/material.dart';
import 'StaffDashboard.dart';
import 'staff_profile.dart';
import '../services/auth_service.dart';

class StaffNavigation extends StatefulWidget {
  const StaffNavigation({super.key});

  @override
  State<StaffNavigation> createState() => _StaffNavigationState();
}

class _StaffNavigationState extends State<StaffNavigation> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
  // Only 2 destinations for staff: Appointments and Profile
    final List<NavigationDestination> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.calendar_today),
        label: 'Appointments',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ];

    final pages = <Widget>[
      const StaffDashboardPage(),
      const StaffProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        actions: [
          TextButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.green.shade200,
        selectedIndex: currentPageIndex,
        destinations: destinations,
      ),
      body: pages[currentPageIndex],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();

                try {
                  await AuthService().logout();

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}