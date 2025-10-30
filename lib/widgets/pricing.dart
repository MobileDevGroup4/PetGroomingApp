import 'package:flutter/material.dart';
import 'package:flutter_app/models/package.dart';

/// Helpers internes
String _suffixFromLabel(String label) {
  // Ex: "70 CHF" -> "CHF", "49.90 chf" -> "chf", "30" -> ""
  final m = RegExp(r'^\s*([\d.,]+)\s*(.*)$').firstMatch(label.trim());
  final sfx = (m != null ? m.group(2) : '') ?? '';
  return sfx.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _formatPrice(Package p, double value) {
  final suffix = _suffixFromLabel(p.priceLabel);
  final txt = (value % 1 == 0)
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return suffix.isEmpty ? txt : '$txt $suffix';
}

/// Affiche le prix principal et, si promo, le prix barré (ancien prix).
class PriceText extends StatelessWidget {
  final Package package;
  final TextStyle? primaryStyle;
  final TextStyle? strikedStyle;
  final MainAxisAlignment alignment;

  const PriceText({
    super.key,
    required this.package,
    this.primaryStyle,
    this.strikedStyle,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mainStyle =
        primaryStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    final strikeStyle =
        strikedStyle ??
        theme.textTheme.bodySmall?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        );

    // Pas de rabais -> on réutilise simplement le label saisi (ex: "70 CHF")
    if (!package.hasDiscount ||
        package.discountedPrice == null ||
        (package.basePrice ?? 0) <= 0) {
      return Text(package.priceLabel, style: mainStyle);
    }

    // Avec rabais -> prix barré + prix actuel formatés avec le suffixe du label
    final oldTxt = _formatPrice(package, package.basePrice!);
    final newTxt = _formatPrice(package, package.discountedPrice!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        // Ancien prix (barré)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(oldTxt, style: strikeStyle),
        ),
        // Nouveau prix (mis en avant)
        Text(newTxt, style: mainStyle),
      ],
    );
  }
}

/// Petit badge style Chip avec -X% (affiché uniquement s'il y a un rabais actif).
class DiscountChip extends StatelessWidget {
  final Package package;
  const DiscountChip({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    if (!package.hasDiscount || (package.discountPercent ?? 0) <= 0) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text(
        '-${package.discountPercent}%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.red.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
