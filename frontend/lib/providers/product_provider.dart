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
        } else {
          _products = [];
        }
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
      }
    } catch (e) {
      _error = 'Network error: $e';
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
        try {
          final newProduct = Product.fromJson(response['data']);
          _products.insert(0, newProduct);
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          _error = 'Error parsing product data: $e';
          _isLoading = false;
          notifyListeners();
          return false;
        }
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

  Future<bool> updateProduct(int productId, Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProduct(productId, productData);
      print('Update product response: $response');
      
      if (response['success'] == true) {
        // Refresh products
        await fetchSellerProducts();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to update product';
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

  Future<bool> deleteProduct(int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteProduct(productId);
      print('Delete product response: $response');
      
      if (response['success'] == true) {
        _products.removeWhere((p) => p.id == productId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to delete product';
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
