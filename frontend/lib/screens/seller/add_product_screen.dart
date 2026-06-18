import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedCategory = 'FOOD';
  bool _isPremium = false;
  bool _isAvailable = true;
  bool _isLoading = false;

  final List<String> _categories = ['FOOD', 'GROCERY', 'CRAFTS', 'MARKET'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isLoading ? Colors.grey : const Color(0xFF2A7DE1),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ITEM NAME',
                  hintText: 'e.g. Traditional Mandasi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Product name required' : null,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'PRICE (MK)',
                  hintText: 'e.g. 1500',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Price required';
                  if (double.tryParse(value) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stock Quantity
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'STOCK QUANTITY',
                  hintText: 'e.g. 100',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Stock quantity required';
                  if (int.tryParse(value) == null) return 'Invalid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'CLASSIFICATION',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'DESCRIPTION',
                  hintText: 'Describe your product...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 16),

              // Premium Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Premium Product'),
                  subtitle: const Text(
                    'Premium products get featured placement',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isPremium,
                  onChanged: (value) => setState(() => _isPremium = value),
                  activeColor: const Color(0xFF2A7DE1),
                ),
              ),

              // Available Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('In Stock'),
                  subtitle: const Text(
                    'Product will be visible to customers',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isAvailable,
                  onChanged: (value) => setState(() => _isAvailable = value),
                  activeColor: Colors.green,
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1A2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'PUBLISH PRODUCT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Get category ID (1=FOOD, 2=GROCERY, 3=CRAFTS, 4=MARKET)
      final categoryMap = {
        'FOOD': 1,
        'GROCERY': 2,
        'CRAFTS': 3,
        'MARKET': 4,
      };

      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': categoryMap[_selectedCategory] ?? 1,
        'stock_quantity': int.parse(_stockController.text.trim()),
        'is_available': _isAvailable,
        'is_premium': _isPremium,
      };

      print('Sending product data: $productData');

      final success = await productProvider.createProduct(productData);
      
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Product published successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${productProvider.error ?? 'Failed to publish product'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
