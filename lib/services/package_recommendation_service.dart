import 'dart:math';

import '../models/package.dart';

/// This is a very simple recommendation. The logic can be extended in future
class PackageRecommendationService {
  static final Random _random = Random();

  /// Returns a random package as recommendation from the provided list
  /// Returns null if the list is empty
  Package? getRandomRecommendation(List<Package> packages) {
    if (packages.isEmpty) return null;

    // Filter only active/visible packages for recommendations
    final availablePackages = packages
        .where((p) => p.isActive && p.visible)
        .toList();

    if (availablePackages.isEmpty) return null;

    // Pick random package
    final randomIndex = _random.nextInt(availablePackages.length);
    return availablePackages[randomIndex];
  }
}
