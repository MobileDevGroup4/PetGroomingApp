import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/package.dart';
import '../utils/package_diff.dart';
import '../screens/date_time_screen.dart';
import '../repositories/packages_repository.dart';

class PackageDetailPage extends StatelessWidget {
  final Package pack;
  final List<Package> allPackages;

  const PackageDetailPage({
    super.key,
    required this.pack,
    required this.allPackages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final added = addedServicesForTier(pack, allPackages);
    final isSignedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF4FA),

      // Ouvre uniquement la sheet
      floatingActionButton: isSignedIn
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              onPressed: () => _openEditBottomSheet(context, pack),
            )
          : null,

      body: CustomScrollView(
        slivers: [
          //SliverAppBar
          SliverAppBar(
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
            expandedHeight: 220,
            title: Text(
              pack.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.fadeTitle,
                StretchMode.zoomBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFF0C2), Color(0xFFE8D8FF)],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: -40,
                    right: -30,
                    child: _GlowCircle(size: 180, color: Colors.white70),
                  ),
                  const Positioned(
                    bottom: -20,
                    left: -10,
                    child: _GlowCircle(size: 140, color: Colors.white54),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _HeaderInfo(
                      badge: pack.badge,
                      durationMinutes: pack.durationMinutes,
                      priceLabel: pack.priceLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 18, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pack.shortDescription,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.black87,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (added.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Highlights',
                      icon: Icons.star_rate_rounded,
                      iconColor: const Color(0xFFFFC107),
                      children: added
                          .map(
                            (s) => _LineItem(
                              leading: const Icon(
                                Icons.star_border_rounded,
                                size: 22,
                              ),
                              text: s,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _SectionCard(
                    title: 'Included Services',
                    icon: Icons.check_circle_rounded,
                    iconColor: Colors.teal,
                    children: [
                      ...pack.services.map(
                        (s) => _LineItem(
                          leading: const Icon(
                            Icons.check_circle_outline,
                            size: 22,
                          ),
                          text: s,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _PrimaryButton(
                    text: 'Book Now',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DateTimeScreen(package: pack),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ouvre la sheet et affiche un SnackBar une fois fermée
  Future<void> _openEditBottomSheet(BuildContext context, Package pack) async {
    final messenger = ScaffoldMessenger.of(context);
    final bool? didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _EditPackageSheet(pack: pack),
    );

    if (didSave == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Package updated')));
    } else if (didSave == false) {
      messenger.showSnackBar(const SnackBar(content: Text('Update failed')));
    }
  }
}

/// ===== Bottom sheet autonome (Stateful) ======================================
class _EditPackageSheet extends StatefulWidget {
  const _EditPackageSheet({required this.pack});
  final Package pack;

  @override
  State<_EditPackageSheet> createState() => _EditPackageSheetState();
}

class _EditPackageSheetState extends State<_EditPackageSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _badgeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _servicesCtrl;
  final _repo = PackagesRepository();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pack.name);
    _priceCtrl = TextEditingController(text: widget.pack.priceLabel);
    _durationCtrl = TextEditingController(
      text: widget.pack.durationMinutes.toString(),
    );
    _badgeCtrl = TextEditingController(text: widget.pack.badge);
    _descCtrl = TextEditingController(text: widget.pack.shortDescription);
    _servicesCtrl = TextEditingController(
      text: widget.pack.services.join('\n'),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _badgeCtrl.dispose();
    _descCtrl.dispose();
    _servicesCtrl.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Package', style: Theme.of(context).textTheme.titleLarge),
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter price label' : null,
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
              validator: (v) {
                final items = _linesToServices(v ?? '');
                return items.isEmpty ? 'Add at least one service' : null;
              },
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      FocusScope.of(context).unfocus();
                      final navigator = Navigator.of(context);
                      final duration = int.parse(_durationCtrl.text.trim());
                      final services = _linesToServices(_servicesCtrl.text);

                      try {
                        await _repo.updatePackageFields(widget.pack.id, {
                          'name': _nameCtrl.text.trim(),
                          'priceLabel': _priceCtrl.text.trim(),
                          'durationMinutes': duration,
                          'badge': _badgeCtrl.text.trim(),
                          'shortDescription': _descCtrl.text.trim(),
                          'services': services,
                        });
                        navigator.pop(true);
                      } catch (_) {
                        navigator.pop(false);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
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

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 40, spreadRadius: 10)],
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final String badge;
  final int durationMinutes;
  final String priceLabel;
  const _HeaderInfo({
    required this.badge,
    required this.durationMinutes,
    required this.priceLabel,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _BadgeChip(text: badge),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Colors.black87),
              const SizedBox(width: 6),
              Text(
                '$durationMinutes min',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          _PricePill(text: priceLabel),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String text;
  const _BadgeChip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDECFEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String text;
  const _PricePill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: const Color(0xFFFFF3CC),
        border: Border.all(color: const Color(0xFFFFC107)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final Widget leading;
  final String text;
  const _LineItem({required this.leading, required this.text});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minLeadingWidth: 6,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: leading,
      title: Text(text, style: const TextStyle(fontSize: 16)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.text, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? .6 : 1,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(48),
            ),
            elevation: 0,
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),
      ),
    );
  }
}
