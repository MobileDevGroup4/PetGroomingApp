import 'package:flutter/material.dart';
import '../models/package.dart';
import '../utils/package_diff.dart';

class PackageDetailPage extends StatelessWidget {
  final Package pack;
  final List<Package> allPackages; // <<< on la reçoit depuis Home

  const PackageDetailPage({
    super.key,
    required this.pack,
    required this.allPackages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final added = addedServicesForTier(pack, allPackages); // <<< ICI la diff

    return Scaffold(
      backgroundColor: const Color(0xFFFAF4FA),
      body: CustomScrollView(
        slivers: [
          // --- SliverAppBar avec titre dans la barre pour éviter le chevauchement ---
          SliverAppBar(
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
            expandedHeight: 220,
            title: Text(
              pack.name,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.fadeTitle, StretchMode.zoomBackground],
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
                  Positioned(top: -40, right: -30, child: _GlowCircle(size: 180, color: Colors.white70)),
                  Positioned(bottom: -20, left: -10, child: _GlowCircle(size: 140, color: Colors.white54)),
                  Positioned(
                    left: 16, right: 16, bottom: 16,
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
                            color: Colors.black87, height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // --- Highlights : s'affiche seulement s'il y a des ajouts ---
                  if (added.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Highlights',
                      icon: Icons.star_rate_rounded,
                      iconColor: const Color(0xFFFFC107),
                      children: [
                        ...added.map((s) => _LineItem(
                              leading: const Icon(Icons.star_border_rounded, size: 22),
                              text: s,
                            )),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Included services ---
                  _SectionCard(
                    title: 'Included Services',
                    icon: Icons.check_circle_rounded,
                    iconColor: Colors.teal,
                    children: [
                      ...pack.services.map((s) => _LineItem(
                            leading: const Icon(Icons.check_circle_outline, size: 22),
                            text: s,
                          )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _PrimaryButton(text: 'Booking coming soon', onPressed: null),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Widgets décor (inchangés) ======
class _GlowCircle extends StatelessWidget {
  final double size; final Color color;
  const _GlowCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 40, spreadRadius: 10)],
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final String badge; final int durationMinutes; final String priceLabel;
  const _HeaderInfo({required this.badge, required this.durationMinutes, required this.priceLabel});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          _BadgeChip(text: badge),
          const Spacer(),
          Row(children: [
            const Icon(Icons.schedule, size: 18, color: Colors.black87),
            const SizedBox(width: 6),
            Text('$durationMinutes min',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(width: 12),
          _PricePill(text: priceLabel),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String text; const _BadgeChip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDECFEE)),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: .2)),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String text; const _PricePill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: const Color(0xFFFFF3CC),
        border: Border.all(color: const Color(0xFFFFC107)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title; final IconData icon; final Color iconColor; final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.iconColor, required this.children});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ]),
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
  final Widget leading; final String text;
  const _LineItem({required this.leading, required this.text});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true, minLeadingWidth: 6, contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: leading, title: Text(text, style: const TextStyle(fontSize: 16)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text; final VoidCallback? onPressed;
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
            elevation: 0, backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white,
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2)),
        ),
      ),
    );
  }
}
