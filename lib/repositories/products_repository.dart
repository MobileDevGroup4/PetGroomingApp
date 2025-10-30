// lib/repositories/products_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductsRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('products');

  // Check if collection is empty and auto-populate if needed
  Future<void> _checkAndPopulateProducts() async {
    try {
      final snapshot = await _collection.limit(1).get();
      if (snapshot.docs.isEmpty) {
        await addSampleProducts();
      }
    } catch (e) {
      print('Error checking products collection: $e');
    }
  }

  // Get all products from Firestore
  Future<List<Product>> getAllProducts() async {
    await _checkAndPopulateProducts();
    try {
      final querySnapshot = await _collection.get();
      return querySnapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  // Stream all products (auto-populate if empty)
  Stream<List<Product>> streamAllProducts() {
    _checkAndPopulateProducts();
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final querySnapshot = await _collection
          .where('category', isEqualTo: category)
          .get();
      return querySnapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  // Stream products by category
  Stream<List<Product>> streamProductsByCategory(String category) {
    return _collection.where('category', isEqualTo: category).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Get single product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return Product.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting product by ID: $e');
      return null;
    }
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    try {
      final querySnapshot = await _collection.get();
      final categories = querySnapshot.docs
          .map((doc) => doc.data()['category'] as String?)
          .where((category) => category != null)
          .cast<String>()
          .toSet()
          .toList();
      categories.sort();
      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Create a new product
  Future<String> createProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
    bool inStock = true,
  }) async {
    try {
      final docRef = await _collection.add({
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'inStock': inStock,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  // Update an existing product
  Future<void> updateProduct(
    String id, {
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
    required bool inStock,
  }) async {
    try {
      await _collection.doc(id).update({
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'inStock': inStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // Update stock status only
  Future<void> updateStockStatus(String id, bool inStock) async {
    try {
      await _collection.doc(id).update({
        'inStock': inStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating stock status: $e');
      rethrow;
    }
  }

  // Update price only
  Future<void> updatePrice(String id, double price) async {
    try {
      await _collection.doc(id).update({
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating price: $e');
      rethrow;
    }
  }

  // Add sample products using createProduct function
  Future<void> addSampleProducts() async {
    final sampleProducts = [
      {
        'name': 'Pet Gentle Shampoo',
        'description':
            'Gentle, hypoallergenic shampoo perfect for sensitive pet skin. Leaves coat soft and shiny.',
        'price': 24.99,
        'imageUrl':
            'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=300',
        'category': 'Grooming',
      },
      {
        'name': 'Premium Pet Food',
        'description':
            'High-quality dry food with natural ingredients. Balanced nutrition for healthy pets.',
        'price': 45.99,
        'imageUrl':
            'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=300',
        'category': 'Food',
      },
      {
        'name': 'Professional Nail Clipper',
        'description':
            'Safe and easy-to-use nail clipper designed for pets. Comfortable grip handle.',
        'price': 15.99,
        'imageUrl':
            'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=300',
        'category': 'Tools',
      },
      {
        'name': 'Soft Bristle Brush',
        'description':
            'Perfect for daily brushing. Gentle on skin, effective on tangles.',
        'price': 18.50,
        'imageUrl':
            'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=300',
        'category': 'Grooming',
      },
      {
        'name': 'Interactive Pet Toy',
        'description':
            'Durable and fun toy to keep your pet entertained for hours.',
        'price': 12.99,
        'imageUrl':
            'https://images.unsplash.com/photo-1585664811087-47f65abbad64?w=300',
        'category': 'Toys',
      },
      {
        'name': 'Healthy Training Treats',
        'description':
            'Natural treats perfect for training. Low calorie and high in flavor.',
        'price': 8.99,
        'imageUrl':
            'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=300',
        'category': 'Food',
      },
    ];

    for (final productData in sampleProducts) {
      await createProduct(
        name: productData['name'] as String,
        description: productData['description'] as String,
        price: productData['price'] as double,
        imageUrl: productData['imageUrl'] as String,
        category: productData['category'] as String,
      );
    }
  }
}