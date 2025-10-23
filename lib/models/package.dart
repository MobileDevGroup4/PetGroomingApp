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

  // ---- Prix & promo ----
  final double? basePrice;              // ex: 70.0 (déduit de priceLabel)
  final int? discountPercent;           // ex: 20
  final DateTime? discountEndAt;        // null = pas de fin / permanent

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
    this.basePrice,
    this.discountPercent,
    this.discountEndAt,
  });

  // ========== Helpers ==========
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

  static double? _parsePriceLabelToDouble(String label) {
    final m = RegExp(r'([\d]+(?:[.,]\d+)?)').firstMatch(label);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', '.'));
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

  // ========== Getters calculés ==========
  /// true s'il y a un pourcentage > 0 et (pas de fin) ou (encore valide)
  bool get hasDiscount {
    final p = discountPercent ?? 0;
    if (p <= 0) return false;
    if (discountEndAt == null) return true;
    return DateTime.now().isBefore(discountEndAt!);
  }

  /// Prix remisé (si possible)
  double? get discountedPrice {
    if (!hasDiscount) return null;
    final base = basePrice;
    final percent = discountPercent ?? 0;
    if (base == null || base <= 0) return null;
    return (base * (1 - percent / 100)).toDouble();
  }

  // ========== Mapping ==========
  factory Package.fromMap(String id, Map<String, dynamic> data) {
    final v = _readVisible(data);
    final ia = data.containsKey('isActive') ? _toBool(data['isActive']) : v;

    // discountEndAt peut être Timestamp Firestore ou String ISO
    DateTime? endAt;
    final rawEnd = data['discountEndAt'];
    if (rawEnd is Timestamp) {
      endAt = rawEnd.toDate();
    } else if (rawEnd is String) {
      endAt = DateTime.tryParse(rawEnd);
    }

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
      basePrice: (data['basePrice'] as num?)?.toDouble() ??
          _parsePriceLabelToDouble(data['priceLabel'] ?? ''),
      discountPercent: (data['discountPercent'] as num?)?.toInt(),
      discountEndAt: endAt,
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
      'isActive': isActive,
      'basePrice': basePrice,
      'discountPercent': discountPercent,
      'discountEndAt': discountEndAt == null ? null : Timestamp.fromDate(discountEndAt!),
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
    double? basePrice,
    int? discountPercent,
    DateTime? discountEndAt,
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
      isActive: isActive ?? this.isActive,
      basePrice: basePrice ?? this.basePrice,
      discountPercent: discountPercent ?? this.discountPercent,
      discountEndAt: discountEndAt ?? this.discountEndAt,
    );
  }
}
