import 'package:flutter/material.dart';
import 'package:flutter_app/pages/appointments.dart';
import 'package:flutter_app/pages/home.dart';
import 'package:flutter_app/pages/profile.dart';
import 'package:flutter_app/pages/store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_app/models/pet.dart';
import 'package:flutter_app/services/pet_service.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

/*
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // for testing
  await FirebaseAuth.instance.signInAnonymously();
  debugPrint('uid = ${FirebaseAuth.instance.currentUser?.uid}');
*/



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If your Firestore rules require auth to read/write, uncomment this:
  // await FirebaseAuth.instance.signInAnonymously();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    /*
    return StreamProvider<List<Pet>>(
      create: (_) => PetService().pets,
      initialData: const [],
      child: MaterialApp(
        // <-- remove const
        debugShowCheckedModeBanner: false,
        home: const Navigation(),
*/
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snap.data;

          if (user == null) {
            // guest UI, no pets provider
            return const Navigation();
          }

          // user logged in → provide their pets
          return StreamProvider<List<Pet>>.value(
            value: PetService(user.uid).pets,
            initialData: const [],
            child: const Navigation(),
          );
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

        // Tabs depend on login (Appointments only when logged in)
        final List<NavigationDestination> destinations = [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          if (isLoggedIn)
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

        // Pages in the same order as destinations
        final List<Widget> pages = [
          const Home(), // index 0
          if (isLoggedIn) Appointments(theme: theme),
          Store(theme: theme),
          Profile(theme: theme),
        ];

        // ✅ Clamp index to avoid "selectedIndex out of range" after login/logout
        final int safeIndex = (currentPageIndex).clamp(
          0,
          destinations.length - 1,
        );

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
            selectedIndex: safeIndex, // use clamped index
            destinations: destinations,
          ),
          body: pages[safeIndex], // use clamped index
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
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();

                try {
                  await AuthService().logout();

                  // ✅ Reset tab to Home after logout to avoid invalid index
                  if (mounted) {
                    setState(() {
                      currentPageIndex = 0;
                    });
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.orange,
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
