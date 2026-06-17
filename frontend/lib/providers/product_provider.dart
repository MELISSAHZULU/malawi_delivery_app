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
      final response = await _apiService.getProducts();
      print('Fetch products response success: ${response['success']}');
      print('Fetch products data: ${response['data']}');
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _products = data.map((item) {
            try {
              return Product.fromJson(item);
            } catch (e) {
              print('Error parsing product: $e');
              print('Product data: $item');
              return null;
            }
          }).whereType<Product>().toList();
          print('Products loaded: ${_products.length}');
        } else {
          _products = [];
          print('Data is not a list: $data');
        }
        _filteredProducts = [];
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

  // This method is for sellers - fetches their own products
  Future<void> fetchSellerProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getSellerProducts();
      print('Fetch seller products response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _products = data.map((item) {
            try {
              return Product.fromJson(item);
            } catch (e) {
              print('Error parsing product: $e');
              return null;
            }
          }).whereType<Product>().toList();
          print('Seller products loaded: ${_products.length}');
        } else {
          _products = [];
        }
        _filteredProducts = [];
      } else {
        _error = response['error'] ?? 'Failed to load seller products';
        print('Error loading seller products: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Network error: $e');
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
