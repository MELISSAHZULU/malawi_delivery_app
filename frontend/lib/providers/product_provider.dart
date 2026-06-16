import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _filteredProducts.isEmpty ? _products : _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the seller products endpoint
      final response = await _apiService.getSellerProducts();
      print('Fetch products response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _products = data.map((item) => Product.fromJson(item)).toList();
        } else {
          _products = [];
        }
        _filteredProducts = [];
        print('Products loaded: ${_products.length}');
      } else {
        _error = response['error'] ?? 'Failed to load products';
        print('Error loading products: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Network error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createProduct(productData);
      print('Create product response: $response');
      
      if (response['success'] == true) {
        final newProduct = Product.fromJson(response['data']);
        _products.insert(0, newProduct);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to create product';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void filterByCategory(String categoryName) {
    if (categoryName == 'ALL ITEMS') {
      _filteredProducts = [];
    } else {
      _filteredProducts = _products.where((p) => 
        p.categoryName?.toUpperCase() == categoryName.toUpperCase()
      ).toList();
    }
    notifyListeners();
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = [];
    } else {
      _filteredProducts = _products.where((p) =>
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.description.toLowerCase().contains(query.toLowerCase()) ||
          p.sellerName.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
