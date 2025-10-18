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

                  final double ratio =
                      constraints.maxWidth < 380 ? 0.74 : 0.78;

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
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final pack = items[i];
                              return PackageCard(
                                pack: pack,
                                highlightsText:
                                    highlightsLabel(pack, items),
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
                                showAdminActions: isSignedIn,
                                onDelete: () async {
                                  final r = PackagesRepository();
                                  try {
                                    await r.deletePackage(pack.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Deleted "${pack.name}"'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Delete failed: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                            childCount: items.length,
                          ),
                        ),
                      ),
                      const SliverPadding(
                          padding: EdgeInsets.only(bottom: 24)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),

      // FABs: + (si connecté) et calendrier
      floatingActionButton: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          final isSignedIn = authSnap.hasData;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isSignedIn) ...[
                FloatingActionButton.small(
                  heroTag: 'fab-add-package',
                  tooltip: 'Add Package',
                  child: const Icon(Icons.add),
                  onPressed: () async {
                    final created = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => const _CreatePackageSheet(),
                    );
                    if (created == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Package created')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
              FloatingActionButton(
                heroTag: 'fab-calendar',
                tooltip: 'Book Appointment',
                child: const Icon(Icons.calendar_today),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const BookingSelectionScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreatePackageSheet extends StatefulWidget {
  const _CreatePackageSheet();

  @override
  State<_CreatePackageSheet> createState() => _CreatePackageSheetState();
}

class _CreatePackageSheetState extends State<_CreatePackageSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PackagesRepository();

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _servicesCtrl = TextEditingController(text: 'Bath\nBrushing');
  final _highlightsCtrl = TextEditingController(text: 'Quick dry');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _badgeCtrl.dispose();
    _descCtrl.dispose();
    _servicesCtrl.dispose();
    _highlightsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create Package',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Price label (e.g. "50 CHF")',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter price label'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _badgeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Badge (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Short description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a description'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _servicesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Included services (one per line)',
                  hintText: 'e.g.\nBath\nBrushing\nEar cleaning',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                validator: (v) =>
                    _linesToServices(v ?? '').isEmpty
                        ? 'Add at least one service'
                        : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _highlightsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Highlights (one per line)',
                  hintText: 'e.g.\nQuick dry\nSensitive shampoo',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      child: const Text('Create'),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        FocusScope.of(context).unfocus();

                        final services =
                            _linesToServices(_servicesCtrl.text);
                        final highlights =
                            _linesToServices(_highlightsCtrl.text);
                        final duration =
                            int.parse(_durationCtrl.text.trim());

                        try {
                          await _repo.createPackage(
                            name: _nameCtrl.text.trim(),
                            shortDescription: _descCtrl.text.trim(),
                            services: services,
                            priceLabel: _priceCtrl.text.trim(),
                            badge: _badgeCtrl.text.trim(),
                            durationMinutes: duration,
                            highlights: highlights,
                            visible: true,
                          );
                          if (mounted) Navigator.of(context).pop(true);
                        } catch (_) {
                          if (mounted) Navigator.of(context).pop(false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _linesToServices(String raw) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final seen = <String>{};
    return [
      for (final s in lines)
        if (seen.add(s)) s,
    ];
  }
}
