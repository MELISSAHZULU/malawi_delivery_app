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

  Future<void> fetchProducts({int? categoryId, String? searchQuery}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getProducts(
        categoryId: categoryId,
        search: searchQuery,
      );
      
      if (response['success'] == true) {
        _products = (response['data'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
        _filteredProducts = [];
      } else {
        _error = response['error'] ?? 'Failed to load products';
      }
    } catch (e) {
      _error = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
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
}
