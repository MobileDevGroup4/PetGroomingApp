import 'package:flutter/material.dart';
import 'package:flutter_app/models/package.dart';

/// Affiche le prix principal et, si promo, le prix barré.
class PriceText extends StatelessWidget {
  final Package package;
  final TextStyle? primaryStyle;
  final TextStyle? strikedStyle;

  const PriceText({
    super.key,
    required this.package,
    this.primaryStyle,
    this.strikedStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainStyle = primaryStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    final strikeStyle = strikedStyle ??
        theme.textTheme.bodySmall?.copyWith(
          decoration: TextDecoration.lineThrough,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        );

    if (package.hasDiscount) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(package.displayPricePrimary, style: mainStyle),
          const SizedBox(width: 8),
          Text(package.displayPriceStriked ?? '', style: strikeStyle),
        ],
      );
    }
    return Text(package.displayPricePrimary, style: mainStyle);
  }
}

/// Petit badge style Chip avec -X%
class DiscountChip extends StatelessWidget {
  final Package package;
  const DiscountChip({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    if (!package.hasDiscount) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        package.discountBadgeText,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
