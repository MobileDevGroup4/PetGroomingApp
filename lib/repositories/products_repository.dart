import '../models/product.dart';

class ProductsRepository {
  static List<Product> getAllProducts() {
    return [
      Product(
        id: 'shampoo-001',
        name: 'Pet Gentle Shampoo',
        description:
            'Gentle, hypoallergenic shampoo perfect for sensitive pet skin. Leaves coat soft and shiny.',
        price: 24.99,
        imageUrl:
            'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=300',
        category: 'Grooming',
      ),
      Product(
        id: 'food-001',
        name: 'Premium Pet Food',
        description:
            'High-quality dry food with natural ingredients. Balanced nutrition for healthy pets.',
        price: 45.99,
        imageUrl:
            'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=300',
        category: 'Food',
      ),
      Product(
        id: 'clipper-001',
        name: 'Professional Nail Clipper',
        description:
            'Safe and easy-to-use nail clipper designed for pets. Comfortable grip handle.',
        price: 15.99,
        imageUrl:
            'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=300',
        category: 'Tools',
      ),
      Product(
        id: 'brush-001',
        name: 'Soft Bristle Brush',
        description:
            'Perfect for daily brushing. Gentle on skin, effective on tangles.',
        price: 18.50,
        imageUrl:
            'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=300',
        category: 'Grooming',
      ),
      Product(
        id: 'toy-001',
        name: 'Interactive Pet Toy',
        description:
            'Durable and fun toy to keep your pet entertained for hours.',
        price: 12.99,
        imageUrl:
            'https://images.unsplash.com/photo-1585664811087-47f65abbad64?w=300',
        category: 'Toys',
      ),
      Product(
        id: 'treat-001',
        name: 'Healthy Training Treats',
        description:
            'Natural treats perfect for training. Low calorie and high in flavor.',
        price: 8.99,
        imageUrl:
            'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=300',
        category: 'Food',
      ),
    ];
  }

  static List<Product> getProductsByCategory(String category) {
    return getAllProducts()
        .where((product) => product.category == category)
        .toList();
  }

  static Product? getProductById(String id) {
    try {
      return getAllProducts().firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<String> getCategories() {
    final products = getAllProducts();
    final categories = products.map((p) => p.category).toSet().toList();
    categories.sort();
    return categories;
  }
}
