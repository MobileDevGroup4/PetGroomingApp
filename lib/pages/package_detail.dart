import 'package:flutter/material.dart';
import '../models/package.dart';
import '../widgets/service_item.dart';

class PackageDetailPage extends StatelessWidget {
  final Package pack;
  const PackageDetailPage({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pack.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // badge + prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(pack.badge)),
                Text(
                  pack.priceLabel,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pack.shortDescription,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Included Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final s in pack.services) ServiceItem(s),
            const SizedBox(height: 24),
            // CTA désactivé (hors scope US)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                child: const Text('Booking coming soon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
