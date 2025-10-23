import 'package:cloud_firestore/cloud_firestore.dart';

class Package {
  final String id;
  final String name;
  final String shortDescription;
  final List<String> services;
  final String priceLabel;
  final String badge;
  final int durationMinutes;
  final bool isActive; // Added: whether the package is active or not

  const Package({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.services,
    required this.priceLabel,
    required this.badge,
    required this.durationMinutes,
    this.isActive = true, // Default: package is active
  });

  /// Creates a Package object from a Firestore document
  factory Package.fromMap(String id, Map<String, dynamic> data) {
    return Package(
      id: id,
      name: data['name'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      priceLabel: data['priceLabel'] ?? '',
      badge: data['badge'] ?? '',
      durationMinutes: (data['durationMinutes'] ?? 0) as int,
      isActive: (data['isActive'] ?? true) as bool, // Default true if missing
    );
  }

  /// Creates a Package object from a FireStore DocumentSnapshot
  factory Package.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Package.fromMap(doc.id, data);
  }

  /// Converts the Package object to a Firestore-friendly map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortDescription': shortDescription,
      'services': services,
      'priceLabel': priceLabel,
      'badge': badge,
      'durationMinutes': durationMinutes,
      'isActive': isActive,
    };
  }

  /// Returns a copy of the current package with optional modifications
  Package copyWith({
    String? name,
    String? shortDescription,
    List<String>? services,
    String? priceLabel,
    String? badge,
    int? durationMinutes,
    bool? isActive,
  }) {
    return Package(
      id: id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      services: services ?? this.services,
      priceLabel: priceLabel ?? this.priceLabel,
      badge: badge ?? this.badge,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
    );
  }
}
