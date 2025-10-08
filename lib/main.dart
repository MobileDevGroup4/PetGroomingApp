import 'package:flutter/material.dart';
import 'package:flutter_app/pages/appointments.dart';
import 'package:flutter_app/pages/home.dart';
import 'package:flutter_app/pages/profile.dart';
import 'package:flutter_app/pages/store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If user is logged in, show Navigation
          if (snapshot.hasData) {
            return const Navigation();
          }

          // If user is NOT logged in, show Navigation (guests can browse)
          return const Navigation();
        },
      ),
    );
  }
}

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final bool isLoggedIn = user != null;

        // Different navigation items based on login status
        final List<NavigationDestination> destinations = [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          if (isLoggedIn) // Only show Appointments if logged in
            const NavigationDestination(
              icon: Icon(Icons.collections_bookmark),
              label: 'Appointments',
            ),
          const NavigationDestination(icon: Icon(Icons.store), label: 'Store'),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ];

        // Different pages based on login status
        final List<Widget> pages = [
          const Home(), // Index 0
          if (isLoggedIn)
            Appointments(theme: theme), // Index 1 (only if logged in)
          Store(theme: theme), // Index 2 (or 1 if guest)
          Profile(theme: theme), // Index 3 (or 2 if guest)
        ];

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            actions: [
              if (!isLoggedIn)
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                )
              else
                TextButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            indicatorColor: Colors.amber,
            selectedIndex: currentPageIndex,
            destinations: destinations,
          ),
          body: pages[currentPageIndex],
        );
      },
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
                Navigator.of(context).pop();

                try {
                  await AuthService().logout();

                  // Reset the index to a valid value after logout
                  if (context.mounted) {
                    setState(() {
                      currentPageIndex = 0;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
