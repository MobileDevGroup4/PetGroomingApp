class Package {
  final String id;
  final String name;
  final String shortDescription;
  final List<String> services;
  final String priceLabel; // "30 CHF"
  final String badge;      // "Best Seller", "New Arrival", "Popular"

  const Package({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.services,
    required this.priceLabel,
    required this.badge,
  });
}
