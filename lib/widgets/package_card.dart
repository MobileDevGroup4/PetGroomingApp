import 'package:flutter/material.dart';
import '../models/package.dart';

class PackageCard extends StatefulWidget {
  final Package pack;
  final VoidCallback? onTap;
  final String? highlightsText;

  const PackageCard({
    super.key,
    required this.pack,
    this.onTap,
    this.highlightsText,
  });

  @override
  State<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final p = widget.pack;
    final theme = Theme.of(context);

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _scale,
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          onTap: () {
            setState(() => _scale = 0.98);
            Future.delayed(const Duration(milliseconds: 120), () {
              setState(() => _scale = 1.0);
              widget.onTap?.call();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface.withOpacity(0.98),
                  theme.colorScheme.surface.withOpacity(0.92),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: badge + duration (fix overflow)
Row(
  children: [
    _Badge(text: p.badge),

    const SizedBox(width: 8),

    
    Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap( // Wrap évite le "RIGHT OVERFLOWED"
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 16),
            Text(
              '${p.durationMinutes} min',
              overflow: TextOverflow.fade, // sécurité
              softWrap: false,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
      ),
    ),
  ],
),
                const SizedBox(height: 12),

                // Title
                Text(
                  p.name,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                // Short description
                Text(
                  p.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 8),

                // Highlights (optional)
                if (widget.highlightsText != null &&
                    widget.highlightsText!.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.highlightsText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                const Spacer(),

                // Price pill
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFFFC107).withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      p.priceLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: theme.colorScheme.surface.withOpacity(0.7),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
