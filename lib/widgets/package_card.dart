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
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne supérieure : badge + durée à droite
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
                            style: const TextStyle(
                              fontSize: 12,
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

              // Nom
              Center(
                child: Text(
                  pack.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                pack.shortDescription,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 6),

              // Highlights (si fournis)
              if (highlightsText != null && highlightsText!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        highlightsText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Prix
              Text(
                pack.priceLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Petit "tag" discret pour le badge
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
        color: Colors.white.withOpacity(0.6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
