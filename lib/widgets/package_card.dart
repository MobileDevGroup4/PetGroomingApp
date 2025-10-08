import 'package:flutter/material.dart';
import '../models/package.dart';

class PackageCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge, // coupe tout micro-débordement
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // occupe juste ce qu'il faut
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne supérieure : badge + durée
              Row(
                children: [
                  _BadgeTag(text: pack.badge),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${pack.durationMinutes} min',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Titre
              Center(
                child: Text(
                  pack.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 8),

              // Description (compressible)
              Text(
                pack.shortDescription,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2, // ajuste 1–3 selon la place
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 6),

              // Highlights (optionnel + compressible)
              if (highlightsText != null && highlightsText!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        highlightsText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Prix
              Text(
                pack.priceLabel,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Petit "tag" de badge
class _BadgeTag extends StatelessWidget {
  final String text;
  const _BadgeTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black26),
        color: Colors.white.withValues(alpha: 0.6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
