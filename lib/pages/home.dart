import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/package_card.dart';
import 'package_detail.dart';
import '../repositories/packages_repository.dart';
import '../models/package.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  String _highlightsFor(Package pack, List<Package> all) {
    final silver = all.firstWhere((p) => p.id == 'silver', orElse: () => all.first);
    final gold   = all.firstWhere((p) => p.id == 'gold', orElse: () => silver);

    if (pack.id == 'silver') return '';
    final baseline = pack.id == 'gold' ? silver : (pack.id == 'platinum' ? gold : silver);
    final base = baseline.services.map((e) => e.toLowerCase()).toSet();
    final added = pack.services.where((s) => !base.contains(s.toLowerCase())).toList();
    if (added.isEmpty) return '';
    final preview = added.length > 2 ? '${added.take(2).join(', ')}…' : added.join(', ');
    return 'Adds: $preview';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo  = PackagesRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Pet Grooming'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Package>>(
        stream: repo.streamPackages(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Firestore error:\n${snap.error}', textAlign: TextAlign.center),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No packages available'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive columns
              int crossAxis = 2;
              if (constraints.maxWidth >= 1000) {
                crossAxis = 4;
              } else if (constraints.maxWidth >= 700) {
                crossAxis = 3;
              } // sinon 2 (téléphone)

              // Ratio carte (ajuste un peu selon ton contenu)
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: ratio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final pack = items[i];
                          return PackageCard(
                            pack: pack,
                            highlightsText: _highlightsFor(pack, items),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PackageDetailPage(pack: pack)),
                              );
                            },
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              );
            },
          );
        },
      ),

      // Fab de test (optionnel) : tu peux supprimer si inutile
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('packages')
                .doc('silver')
                .get();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('silver exists: ${doc.exists}\n${doc.data()}')),
            );
          } catch (e) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Firestore error: $e')),
            );
          }
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}
