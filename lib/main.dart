import 'package:flutter/material.dart';
import 'package:flutter_app/pages/appointments.dart';
import 'package:flutter_app/pages/home.dart';
import 'package:flutter_app/pages/profile.dart';
import 'package:flutter_app/pages/store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Navigation());
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
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark),
            label: 'Appointments',
          ),
          NavigationDestination(icon: Icon(Icons.store), label: 'Store'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: <Widget>[
        /// Home page
        Home(theme: theme),

        // Appointments
        Appointments(theme: theme),

        /// Store page
        Store(theme: theme),

        // Profile
        Profile(theme: theme),
      ][currentPageIndex],
    );
  }
}
