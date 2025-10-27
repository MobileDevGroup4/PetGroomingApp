import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'StaffDashboard.dart';
import 'staff_profile.dart';
import 'staff_aviability.dart';
import 'staff_schedule.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'staff_schedule.dart';
class StaffNavigation extends StatefulWidget {
  const StaffNavigation({super.key});

  @override
  State<StaffNavigation> createState() => _StaffNavigationState();
}

class _StaffNavigationState extends State<StaffNavigation> {
  int currentPageIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;
  String _headerName = '';
  String? _headerImageUrl;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  // Purple theme colors
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color lightPurpleBackground = Color(0xFFFAF4FA);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initProfileListener();
    
    // Verify staff status on init
    _verifyStaffStatus();
  }

  Future<void> _verifyStaffStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const App()),
          (route) => false,
        );
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      
      final isStaff = doc.exists && (doc.data()?['isStaff'] as bool? ?? false);
      
      if (!isStaff && mounted) {
        // If not staff, redirect to main app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const App()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error verifying staff status: $e');
    }
  }

  void _initProfileListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Listen to real-time updates of the user's profile document
    _profileSub = FirebaseFirestore.instance
        .collection('profiles')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final name = (data['name'] as String?)?.trim();
      final imageUrl = data['profileImage'] as String?;

      if (mounted) {
        setState(() {
          _headerName = name != null && name.isNotEmpty
              ? name
              : (user.displayName ?? user.email?.split('@').first ?? 'Staff');
          _headerImageUrl = imageUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _profileSub?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // Hide header when scrolling up, show when scrolling down
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isHeaderVisible) {
          setState(() => _isHeaderVisible = false);
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isHeaderVisible) {
          setState(() => _isHeaderVisible = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<NavigationDestination> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.calendar_today),
        label: 'Appointments',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_note),
        label: 'Schedule',
      ),
      const NavigationDestination(
        icon: Icon(Icons.schedule),
        label: 'Availability',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ];

    final pages = <Widget>[
      const StaffDashboardPage(),
      const StaffSchedulePage(),
      const StaffAvailability(),
      const StaffProfile(),
    ];

    final user = FirebaseAuth.instance.currentUser;
    final display = _headerName.isNotEmpty
        ? _headerName
        : (user?.displayName ?? user?.email?.split('@').first ?? 'Staff');
    final firstName = display.split(' ').first;
    final today = DateFormat('EEEE, d MMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: lightPurpleBackground,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 110,
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: primaryPurple,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryPurple,
                        primaryPurple.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(
                    top: 28,
                    left: 12,
                    right: 12,
                    bottom: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: _headerImageUrl != null
                            ? NetworkImage(_headerImageUrl!)
                            : null,
                        child: _headerImageUrl == null
                            ? Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome, $firstName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logout button
                      IconButton(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: pages[currentPageIndex],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: primaryPurple.withOpacity(0.2),
        selectedIndex: currentPageIndex,
        destinations: destinations,
      ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();

                try {
                  await AuthService().logout();

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text('Logged out successfully'),
                        backgroundColor: primaryPurple,
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

