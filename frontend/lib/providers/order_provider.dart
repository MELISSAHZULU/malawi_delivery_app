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
      print('Fetch orders response success: ${response['success']}');
      
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
      final existingOrder = _orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );
      _currentOrder = existingOrder;
      print('Found order in list: ${_currentOrder?.orderNumber}');
    } catch (e) {
      try {
        final response = await _apiService.getOrder(orderId);
        print('Track order response: $response');
        
        if (response['success'] == true) {
          try {
            _currentOrder = Order.fromJson(response['data']);
            print('Order loaded: ${_currentOrder?.orderNumber}');
          } catch (parseError) {
            _error = 'Error parsing order: $parseError';
          }
        } else {
          _error = response['error'] ?? 'Order not found';
        }
      } catch (apiError) {
        _error = 'Network error: $apiError';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateOrderStatusLocally(String orderId, String newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      // Create a new order object with updated status
      final oldOrder = _orders[index];
      final updatedOrder = Order(
        id: oldOrder.id,
        orderNumber: oldOrder.orderNumber,
        status: newStatus,
        items: oldOrder.items,
        subtotal: oldOrder.subtotal,
        deliveryFee: oldOrder.deliveryFee,
        total: oldOrder.total,
        deliveryAddress: oldOrder.deliveryAddress,
        driverName: oldOrder.driverName,
        driverPhone: oldOrder.driverPhone,
        createdAt: oldOrder.createdAt,
        estimatedDeliveryTime: oldOrder.estimatedDeliveryTime,
        paymentStatus: oldOrder.paymentStatus,
        paymentMethod: oldOrder.paymentMethod,
        sellerName: oldOrder.sellerName,
        buyerName: oldOrder.buyerName,
      );
      _orders[index] = updatedOrder;
      if (_currentOrder?.id == orderId) {
        _currentOrder = updatedOrder;
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
