import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getOrders();
      print('Fetch orders response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _orders = data.map((item) {
            try {
              return Order.fromJson(item);
            } catch (e) {
              print('Error parsing order: $e');
              return null;
            }
          }).whereType<Order>().toList();
          print('Orders loaded: ${_orders.length}');
        } else {
          _orders = [];
          print('Data is not a list: $data');
        }
      } else {
        _error = response['error'] ?? 'Failed to fetch orders';
        print('Error loading orders: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Network error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createOrder(orderData);
      print('Create order response: $response');
      
      if (response['success'] == true) {
        try {
          final newOrder = Order.fromJson(response['data']);
          _orders.insert(0, newOrder);
          _currentOrder = newOrder;
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          _error = 'Error parsing order data: $e';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error = response['error'] ?? 'Failed to create order';
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

  Future<void> trackOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, try to find the order in the existing list
      final existingOrder = _orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );
      _currentOrder = existingOrder;
      print('Found order in list: ${_currentOrder?.orderNumber}');
    } catch (e) {
      // If not found in list, fetch from API
      try {
        final response = await _apiService.getOrder(orderId);
        print('Track order response: $response');
        
        if (response['success'] == true) {
          try {
            _currentOrder = Order.fromJson(response['data']);
            print('Order loaded: ${_currentOrder?.orderNumber}');
          } catch (parseError) {
            _error = 'Error parsing order: $parseError';
            print('Parse error: $parseError');
          }
        } else {
          _error = response['error'] ?? 'Order not found';
          print('Error tracking order: $_error');
        }
      } catch (apiError) {
        _error = 'Network error: $apiError';
        print('Network error: $apiError');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateOrderStatus(Order order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order;
      if (_currentOrder?.id == order.id) {
        _currentOrder = order;
      }
      notifyListeners();
    }
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
