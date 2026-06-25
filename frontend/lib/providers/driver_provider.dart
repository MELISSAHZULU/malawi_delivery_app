import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order.dart';

class DriverProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Order> _assignedOrders = [];
  List<Order> _availableOrders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get assignedOrders => _assignedOrders;
  List<Order> get availableOrders => _availableOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAssignedOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getDriverOrders();
      print('Fetch driver orders response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _assignedOrders = data.map((item) {
            try {
              final orderDetails = item['order_details'] as Map<String, dynamic>?;
              if (orderDetails == null) return null;
              // Inject the assignment id and status into order_details before parsing
              orderDetails['assignment_id'] = item['id'].toString();
              // Add assignment status if available
              if (item['status'] != null) {
                orderDetails['assignment_status'] = item['status'].toString();
              }
              // Add driver name if available
              if (item['driver_name'] != null) {
                orderDetails['driver_name'] = item['driver_name'].toString();
              }
              return Order.fromJson(orderDetails);
            } catch (e) {
              print('Error parsing order: $e');
              return null;
            }
          }).whereType<Order>().toList();
          print('Driver orders loaded: ${_assignedOrders.length}');
        } else {
          _assignedOrders = [];
        }
      } else {
        _error = response['error'] ?? 'Failed to fetch driver orders';
        print('Error loading driver orders: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Network error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ FIXED: fetchAvailableOrders handles both plain list and wrapped response
  Future<void> fetchAvailableOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dynamic response = await _apiService.getAvailableOrders();
      print('Fetch available orders response: $response');
      
      // Handle both cases:
      // 1. Plain list: [{...}, {...}]
      // 2. Wrapped response: {'success': true, 'data': [{...}]}
      List<dynamic> ordersList = [];
      
      if (response is List) {
        // Plain list response
        ordersList = response;
        print('✅ Available orders: plain list with ${ordersList.length} items');
      } else if (response is Map<String, dynamic>) {
        // Wrapped response
        if (response['success'] == true) {
          final data = response['data'];
          if (data is List) {
            ordersList = data;
            print('✅ Available orders: wrapped list with ${ordersList.length} items');
          } else {
            print('⚠️ Response data is not a list: ${data.runtimeType}');
          }
        } else {
          _error = response['error'] ?? 'Failed to fetch available orders';
          print('Error loading available orders: $_error');
        }
      } else {
        print('⚠️ Unexpected response type: ${response.runtimeType}');
        _error = 'Unexpected response format';
      }
      
      // Parse the orders list
      _availableOrders = ordersList.map((item) {
        try {
          return Order.fromJson(item as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing available order: $e');
          return null;
        }
      }).whereType<Order>().toList();
      
      print('Available orders parsed: ${_availableOrders.length}');
      
    } catch (e) {
      _error = 'Network error: $e';
      print('Network error fetching available orders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ FIXED: acceptDelivery refreshes both lists correctly
  Future<bool> acceptDelivery(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.acceptDelivery(orderId);
      print('Accept delivery response: $response');
      
      if (response['success'] == true) {
        // ✅ FIXED: Refresh both lists — accepted order moves from available to assigned
        await fetchAssignedOrders();
        await fetchAvailableOrders();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to accept delivery';
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

  Future<bool> updateDeliveryStatus(String orderId, String action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateDeliveryStatus(orderId, action);
      print('Update delivery status response: $response');
      
      if (response['success'] == true) {
        await fetchAssignedOrders();
        await fetchAvailableOrders();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to update delivery status';
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

  // Method to get a single order by ID
  Order? getOrderById(String id) {
    try {
      final results = _assignedOrders.where((order) => order.id.toString() == id);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  // Method to get order status
  String getOrderStatus(String id) {
    final order = getOrderById(id);
    return order?.status ?? 'unknown';
  }

  // Method to check if order is in a specific state
  bool isOrderPending(String id) {
    final order = getOrderById(id);
    if (order == null) return false;
    final status = order.status.toLowerCase();
    return status == 'pending' || status == 'accepted' || status == 'confirmed' || status == 'ready';
  }

  bool isOrderPickedUp(String id) {
    final order = getOrderById(id);
    if (order == null) return false;
    final status = order.status.toLowerCase();
    return status == 'picked_up' || status == 'in_transit' || status == 'driving';
  }

  bool isOrderDelivered(String id) {
    final order = getOrderById(id);
    if (order == null) return false;
    final status = order.status.toLowerCase();
    return status == 'delivered' || status == 'completed';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset method for logout
  void reset() {
    _assignedOrders = [];
    _availableOrders = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}