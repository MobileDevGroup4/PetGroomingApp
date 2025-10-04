import '../models/package.dart';

const packages = <Package>[
  Package(
    id: 'silver',
    name: 'Silver',
    shortDescription: 'Bath & Care',
    services: ['Bath', 'Brushing', 'Ear cleaning'],
    priceLabel: '30 CHF',
    badge: 'Best Seller',
  ),
  Package(
    id: 'gold',
    name: 'Gold',
    shortDescription: 'Bath, Care & Nail Clipping',
    services: ['Bath', 'Brushing', 'Nail clipping', 'Ear cleaning'],
    priceLabel: '50 CHF',
    badge: 'New Arrival',
  ),
  Package(
    id: 'platinum',
    name: 'Platinum',
    shortDescription: 'Bath, Care, Nail, Hair Removal & Massage',
    services: [
      'Deep bath & drying',
      'Hair removal (undercoat)',
      'Nail clipping',
      'Massage',
      'Perfume (optional)',
    ],
    priceLabel: '100 CHF',
    badge: 'Popular',
  ),
];
