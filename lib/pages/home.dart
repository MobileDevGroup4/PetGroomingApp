import 'package:flutter/material.dart';
import '../data/packages.dart';
import '../widgets/package_card.dart';
import 'package_detail.dart';

class Home extends StatelessWidget {
  const Home({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
            // ---- TITLE SECTION ----
            Text(
              'Our Packages',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ---- GRID OF PACKAGE CARDS ----
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: packages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final pack = packages[index];
                return PackageCard(
                  pack: pack,
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

            const SizedBox(height: 24),
            const Divider(height: 32),

            // ---- INFO SECTION ----
            Text(
              'About Our Services',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We offer professional grooming packages for your pets, '
              'adapted to their needs and comfort. Each package includes '
              'specific treatments to keep your pets happy and healthy.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
