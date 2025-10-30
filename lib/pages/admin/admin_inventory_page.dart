import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/products_repository.dart';
import '../../models/product.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  final _repo = ProductsRepository();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: FutureBuilder<List<String>>(
              future: _repo.getCategories(),
              builder: (context, snapshot) {
                final categories = ['All', ...?snapshot.data];
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = category),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Products list
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _selectedCategory == 'All'
                  ? _repo.streamAllProducts()
                  : _repo.streamProductsByCategory(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var products = snapshot.data ?? [];
                
                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  products = products.where((p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.description.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No products in this category' : 'No products found',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
                      product: product,
                      onEdit: () => _editProduct(product),
                      onDelete: () => _deleteProduct(product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _addProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductFormPage(),
      ),
    );
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(product: product),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.name} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.category),
            Text('\$${product.price.toStringAsFixed(2)}', 
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(product.inStock ? 'In Stock' : 'Out of Stock'),
              backgroundColor: product.inStock ? Colors.green[100] : Colors.red[100],
              labelStyle: TextStyle(
                color: product.inStock ? Colors.green[900] : Colors.red[900],
                fontSize: 12,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// Product Form Page
class ProductFormPage extends StatefulWidget {
  final Product? product;
  
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProductsRepository();
  
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _categoryCtrl;
  late bool _inStock;
  
  bool _saving = false;
  List<String> _existingCategories = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _imageUrlCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _inStock = p?.inStock ?? true;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _repo.getCategories();
    setState(() => _existingCategories = cats);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageUrlCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Description required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              validator: (v) {
                final price = double.tryParse(v ?? '');
                if (price == null || price <= 0) return 'Enter valid price';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _categoryCtrl.text),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _existingCategories;
                }
                return _existingCategories.where((cat) =>
                  cat.toLowerCase().contains(textEditingValue.text.toLowerCase())
                );
              },
              onSelected: (selection) => _categoryCtrl.text = selection,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                controller.text = _categoryCtrl.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category),
                    helperText: 'Select existing or type new category',
                  ),
                  onChanged: (v) => _categoryCtrl.text = v,
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Category required' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _imageUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Image URL required' : null,
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('In Stock'),
              subtitle: Text(_inStock ? 'Available for purchase' : 'Currently unavailable'),
              value: _inStock,
              onChanged: (v) => setState(() => _inStock = v),
            ),
            
            const SizedBox(height: 24),
            
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Product'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final description = _descCtrl.text.trim();
      final price = double.parse(_priceCtrl.text.trim());
      final imageUrl = _imageUrlCtrl.text.trim();
      final category = _categoryCtrl.text.trim();

      if (widget.product == null) {
        // Create new product
        await _repo.createProduct(
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl,
          category: category,
          inStock: _inStock,
        );
      } else {
        // Update existing product
        await _repo.updateProduct(
          widget.product!.id,
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl,
          category: category,
          inStock: _inStock,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product ${widget.product == null ? "created" : "updated"}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}