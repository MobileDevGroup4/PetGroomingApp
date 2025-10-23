import 'package:flutter/material.dart';
import '../widgets/package_card.dart';
import 'package_detail.dart';
import '../repositories/packages_repository.dart';
import '../models/package.dart';
import '../utils/package_diff.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/booking_selection_screen.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  // Color selection based on package name
  Color getPackageColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bronze')) return const Color(0xFFCD7F32);
    if (lower.contains('silver')) return const Color(0xFFB0B0B0);
    if (lower.contains('gold')) return const Color(0xFFFFC107);
    if (lower.contains('platinum')) return const Color(0xFFD6E4E5);
    return const Color(0xFF7C3AED); // default purple
  }

  IconData getPackageIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bronze')) return Icons.workspace_premium;
    if (lower.contains('silver')) return Icons.star_border_rounded;
    if (lower.contains('gold')) return Icons.star_rounded;
    if (lower.contains('platinum')) return Icons.diamond;
    return Icons.card_membership;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = PackagesRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 6,
        backgroundColor: Colors.teal,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.pets, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Pet Grooming Center',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          final bool isSignedIn = authSnap.hasData;

          return StreamBuilder<List<Package>>(
            stream: repo.streamPackages(onlyActive: isSignedIn ? null : true),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Firestore error:\n${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('No packages available'));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxis = 2;
                  if (constraints.maxWidth >= 1000) {
                    crossAxis = 4;
                  } else if (constraints.maxWidth >= 700) {
                    crossAxis = 3;
                  }

                  final double ratio = constraints.maxWidth < 380 ? 0.74 : 0.78;

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Our Packages',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxis,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: ratio,
                              ),
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final pack = items[i];
                            return PackageCard(
                              pack: pack,
                              highlightsText: highlightsLabel(pack, items),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PackageDetailPage(
                                      pack: pack,
                                      allPackages: items,
                                    ),
                                  ),
                                );
                              },
                            );
                          }, childCount: items.length),
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingSelectionScreen(),
            ),
          );
        },
        tooltip: 'Book Appointment',
        child: const Icon(Icons.calendar_today),
      ),
    );
  }
}
