import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/package_card.dart';
import 'package_detail.dart';
import '../repositories/packages_repository.dart';
import '../models/package.dart';
import '../utils/package_diff.dart';

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

      body: StreamBuilder<List<Package>>(
        stream: repo.streamPackages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Firestore Error:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No packages available.'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxis = 2;
              if (constraints.maxWidth >= 1000) crossAxis = 4;
              else if (constraints.maxWidth >= 700) crossAxis = 3;

              final double ratio = constraints.maxWidth < 380 ? 0.75 : 0.8;

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFCCFBF1), Color(0xFFA7F3D0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Icon(Icons.favorite, color: Colors.teal, size: 34),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pamper your pets with our premium grooming packages!',
                                style: TextStyle(
                                  color: Color(0xFF064E3B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Package Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: ratio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final pack = items[i];
                          final color = getPackageColor(pack.name);
                          final icon = getPackageIcon(pack.name);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PackageDetailPage(
                                    pack: pack,
                                    allPackages: items,
                                  ),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: color.withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Gradient header
                                  Container(
                                    height: 90,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [color, color.withOpacity(0.7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(icon, size: 40, color: Colors.white),
                                    ),
                                  ),
                                  // Content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            pack.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (highlightsLabel(pack, items).isNotEmpty)
                                            Container(
                                              margin: const EdgeInsets.only(top: 6),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                highlightsLabel(pack, items),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: color,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          // Button
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              margin: const EdgeInsets.only(top: 10),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'View Details',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(Icons.arrow_forward_ios_rounded,
                                                        color: Colors.white, size: 12),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        elevation: 6,
        onPressed: () async {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('packages')
                .doc('silver')
                .get();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.teal.shade700,
                content: Text('Silver exists: ${doc.exists}\n${doc.data()}'),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade400,
                content: Text('Firestore error: $e'),
              ),
            );
          }
        },
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }
}
