import 'package:flutter/material.dart';
import '../data/packages.dart';
import '../widgets/package_card.dart';
import 'package_detail.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  String _highlightsFor(pack) {
    final silver = packages.firstWhere((p) => p.id == 'silver');
    if (pack.id == 'silver') return '';
    final base = silver.services.map((e) => e.toLowerCase()).toSet();
    final added = pack.services.where((s) => !base.contains(s.toLowerCase())).toList();
    if (added.isEmpty) return '';
    final preview = added.length > 2 ? '${added.take(2).join(', ')}…' : added.join(', ');
    return 'Adds: $preview';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Pet Grooming'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              itemCount: packages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final pack = packages[index];
                return PackageCard(
                  pack: pack,
                  highlightsText: _highlightsFor(pack),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PackageDetailPage(pack: pack),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
