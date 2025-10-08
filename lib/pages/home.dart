import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ⬅️ ajout
import '../widgets/package_card.dart';
import 'package_detail.dart';
import '../repositories/packages_repository.dart';
import '../models/package.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  String _highlightsFor(Package pack, List<Package> all) {
    // baseline: Gold vs Silver, Platinum vs Gold
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
      appBar: AppBar(title: const Text('Welcome to Pet Grooming'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Package>>(
          stream: repo.streamPackages(), // 🔥 Firestore
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Packages',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, i) {
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
                ),
              ],
            );
          },
        ),
      ),

      // ⬇️ Bouton de test Firestore (doc 'silver')
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
