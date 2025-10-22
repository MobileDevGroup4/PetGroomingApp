import 'package:cloud_firestore/cloud_firestore.dart';

class Package {
  final String id;
  final String name;
  final String shortDescription;
  final List<String> services;

  /// Libellé saisi côté back-office, ex: "CHF 89.-"
  final String priceLabel;

  /// Prix numérique pour les calculs. Si absent en base, on le déduit de priceLabel.
  final double basePrice;

  final String badge;
  final int durationMinutes;
  final List<String> highlights;

  final bool visible;
  final bool isActive;

  /// Pourcentage de remise (0–90). Null ou 0 => pas de remise.
  final int? discountPercent;

  const Package({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.services,
    required this.priceLabel,
    required this.basePrice,
    required this.badge,
    required this.durationMinutes,
    this.highlights = const [],
    this.visible = true,
    this.isActive = true,
    this.discountPercent,
  });

  // -------------------- Utils bool --------------------
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

  // -------------------- Parse du label en double --------------------
  /// Exemples acceptés: "CHF 89.-", "89", "89,90", "CHF 89.90"
  static double _parsePriceLabelToDouble(String? label) {
    if (label == null) return 0;
    final m = RegExp(r'(\d+([.,]\d+)?)').firstMatch(label);
    if (m == null) return 0;
    final raw = m.group(1)!.replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  // -------------------- Factory --------------------
  factory Package.fromMap(String id, Map<String, dynamic> data) {
    final v = _readVisible(data);
    final ia = data.containsKey('isActive') ? _toBool(data['isActive']) : v;

    final String pl = (data['priceLabel'] ?? '') as String;
    final double bp = (data['basePrice'] as num?)?.toDouble() ??
        _parsePriceLabelToDouble(pl);

    return Package(
      id: id,
      name: (data['name'] ?? '') as String,
      shortDescription: (data['shortDescription'] ?? '') as String,
      services: List<String>.from(data['services'] ?? const []),
      priceLabel: pl,
      basePrice: bp,
      badge: (data['badge'] ?? '') as String,
      durationMinutes: (data['durationMinutes'] is int)
          ? data['durationMinutes'] as int
          : int.tryParse('${data['durationMinutes']}') ?? 0,
      highlights: List<String>.from(data['highlights'] ?? const []),
      visible: v,
      isActive: ia,
      discountPercent: (data['discountPercent'] as num?)?.toInt(),
    );
  }

  factory Package.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Package.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'shortDescription': shortDescription,
      'services': services,
      'priceLabel': priceLabel,
      'basePrice': basePrice,
      'badge': badge,
      'durationMinutes': durationMinutes,
      'highlights': highlights,
      'visible': visible,
      'isPublic': visible,
      'isActive': visible,
    };

    if ((discountPercent ?? 0) > 0) {
      map['discountPercent'] = discountPercent;
    }
    return map;
  }

  Package copyWith({
    String? name,
    String? shortDescription,
    List<String>? services,
    String? priceLabel,
    double? basePrice,
    String? badge,
    int? durationMinutes,
    List<String>? highlights,
    bool? visible,
    bool? isActive,
    int? discountPercent,
  }) {
    final newVisible = visible ?? this.visible;
    return Package(
      id: id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      services: services ?? this.services,
      priceLabel: priceLabel ?? this.priceLabel,
      basePrice: basePrice ?? this.basePrice,
      badge: badge ?? this.badge,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      highlights: highlights ?? this.highlights,
      visible: newVisible,
      isActive: isActive ?? newVisible,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }

  // -------------------- Getters promo & affichage --------------------
  bool get hasDiscount => (discountPercent ?? 0) > 0;

  /// Prix remisé (arrondi à 2 décimales).
  double get discountedPrice {
    if (!hasDiscount) return basePrice;
    final p = basePrice * (1 - (discountPercent! / 100));
    return double.parse(p.toStringAsFixed(2));
  }

  double get discountAmount {
    if (!hasDiscount) return 0;
    return double.parse((basePrice - discountedPrice).toStringAsFixed(2));
    }

  /// Badge texte "-20%" par ex.
  String get discountBadgeText => hasDiscount ? '-${discountPercent!}%' : '';

  static String _fmt(double v) => 'CHF ${v.toStringAsFixed(2)}';

  /// Prix principal affiché (remisé si promo, sinon normal)
  String get displayPricePrimary =>
      hasDiscount ? _fmt(discountedPrice) : _fmt(basePrice);

  /// Prix barré à afficher quand promo active
  String? get displayPriceStriked => hasDiscount ? _fmt(basePrice) : null;
}
