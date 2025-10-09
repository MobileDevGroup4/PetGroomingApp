class Package {
  final String id;
  final String name;
  final String shortDescription;
  final List<String> services;
  final String priceLabel;
  final String badge;
  final int durationMinutes;

  const Package({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.services,
    required this.priceLabel,
    required this.badge,
    required this.durationMinutes,
  });
}
