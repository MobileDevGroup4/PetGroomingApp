import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../widgets/pet_section.dart';
import '../screens/booking_screen.dart';
import '../screens/booking_selection_screen.dart';
import '../screens/user/profile_edit.dart';
import 'dart:typed_data';
import '../services/storage_service.dart';

final fsStorage = FirestoreStorageService();

class Profile extends StatelessWidget {
  const Profile({super.key, required this.theme});

  final ThemeData theme;


  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox.expand(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;

            if (user == null) {
              // NOT logged in
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text('Guest User', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToLogin(context),
                      icon: const Icon(Icons.login),
                      label: const Text('Login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // User IS logged in - show combined profile view
              return Column(
                children: [
                  const SizedBox(height: 16),
                  FutureBuilder<Uint8List?>(
                  future: fsStorage.loadProfileImage(uid: user.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const CircleAvatar(radius: 48, child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (snap.hasError) {
                      debugPrint('avatar load error: ${snap.error}');
                      return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48, color: Colors.green));
                    }

                    final bytes = snap.data;
                    debugPrint('avatar bytes length: ${bytes?.length}');
                    final img = (bytes != null && bytes.isNotEmpty) ? MemoryImage(bytes) : null;

                    return CircleAvatar(
                      radius: 48,
                      backgroundImage: img,
                      child: img == null
                          ? const Icon(Icons.person, size: 48, color: Colors.green)
                          : null,
                    );
                  },
                ),
                  const SizedBox(height: 8),
                  Text('Welcome!', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    user.email ?? 'No email',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // "Book a service" button from the feature branch
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookingSelectionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Book a service'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),


                  // "Edit your profile" button 
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit your profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // "My Pets" section from the dev branch
                  const Text(
                    "My Pets",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: PetSection()),
                  const SizedBox(height: 16),

                  // Unified "Logout" button
                  ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
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
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                navigator.pop(); // Close dialog before async gap

                try {
                  await AuthService().logout();
                  // Auth state will automatically update the UI
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
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
