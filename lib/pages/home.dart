import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/package_card.dart';
import 'package_detail.dart';
import '../repositories/packages_repository.dart';
import '../models/package.dart';
import '../utils/package_diff.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/booking_selection_screen.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = PackagesRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Pet Grooming'),
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
