import 'package:cloud_firestore/cloud_firestore.dart';

class Package {
  final String id;
  final String name;
  final String shortDescription;
  final List<String> services;
  final String priceLabel;
  final String badge;
  final int durationMinutes;
  final List<String> highlights;

  final bool visible;
  final bool isActive;

  const Package({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.services,
    required this.priceLabel,
    required this.badge,
    required this.durationMinutes,
    this.highlights = const [],
    this.visible = true,
    this.isActive = true,
  });

  static bool _toBool(dynamic v, {bool defaultValue = true}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    return defaultValue;
  }

  static bool _readVisible(Map<String, dynamic> data) {
    return _toBool(
      data['visible'] ??
          data['isPublic'] ??
          data['public'] ??
          data['active'] ??
          data['isActive'],
      defaultValue: true,
    );
  }

  factory Package.fromMap(String id, Map<String, dynamic> data) {
    final v = _readVisible(data);
    final ia = data.containsKey('isActive') ? _toBool(data['isActive']) : v;

    return Package(
      id: id,
      name: data['name'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      services: List<String>.from(data['services'] ?? const []),
      priceLabel: data['priceLabel'] ?? '',
      badge: data['badge'] ?? '',
      durationMinutes: (data['durationMinutes'] ?? 0) is int
          ? data['durationMinutes'] as int
          : int.tryParse('${data['durationMinutes']}') ?? 0,
      highlights: List<String>.from(data['highlights'] ?? const []),
      visible: v,
      isActive: ia,
    );
  }

  factory Package.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Package.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortDescription': shortDescription,
      'services': services,
      'priceLabel': priceLabel,
      'badge': badge,
      'durationMinutes': durationMinutes,
      'highlights': highlights,
      'visible': visible,
      'isPublic': visible,
      'isActive': visible,
    };
  }

  Package copyWith({
    String? name,
    String? shortDescription,
    List<String>? services,
    String? priceLabel,
    String? badge,
    int? durationMinutes,
    List<String>? highlights,
    bool? visible,
    bool? isActive,
  }) {
    final newVisible = visible ?? this.visible;
    return Package(
      id: id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      services: services ?? this.services,
      priceLabel: priceLabel ?? this.priceLabel,
      badge: badge ?? this.badge,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      highlights: highlights ?? this.highlights,
      visible: newVisible,
      isActive: isActive ?? newVisible,
    );
  }
}
