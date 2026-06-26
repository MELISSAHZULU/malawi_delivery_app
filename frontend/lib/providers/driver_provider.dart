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
              
              // Add assignment data to order details
              orderDetails['assignment_id'] = item['id'].toString();
              if (item['status'] != null) {
                orderDetails['assignment_status'] = item['status'].toString();
              }
              if (item['driver_name'] != null) {
                orderDetails['driver_name'] = item['driver_name'].toString();
              }
              if (item['driver_phone'] != null) {
                orderDetails['driver_phone'] = item['driver_phone'].toString();
              }
              if (item['seller_name'] != null) {
                orderDetails['seller_name'] = item['seller_name'].toString();
              }
              if (item['delivery_address'] != null) {
                orderDetails['delivery_address'] = item['delivery_address'].toString();
              }
              if (item['customer_name'] != null) {
                orderDetails['customer_name'] = item['customer_name'].toString();
              }
              if (item['customer_phone'] != null) {
                orderDetails['customer_phone'] = item['customer_phone'].toString();
              }
              
              print('✅ Parsing order: ${orderDetails['order_number']}');
              print('✅ Status: ${orderDetails['status']}');
              print('✅ Seller: ${orderDetails['seller_name']}');
              print('✅ Customer: ${orderDetails['customer_name']}');
              
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

  Future<void> fetchAvailableOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dynamic response = await _apiService.getAvailableOrders();
      print('Fetch available orders response: $response');
      
      List<dynamic> ordersList = [];
      
      if (response is List) {
        ordersList = response;
        print('✅ Available orders: plain list with ${ordersList.length} items');
      } else if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
          final data = response['data'];
          if (data is List) {
            ordersList = data;
            print('✅ Available orders: wrapped list with ${ordersList.length} items');
          }
        } else {
          _error = response['error'] ?? 'Failed to fetch available orders';
        }
      }
      
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

  Future<bool> acceptDelivery(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.acceptDelivery(orderId);
      print('Accept delivery response: $response');
      
      if (response['success'] == true) {
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

  Order? getOrderById(String id) {
    try {
      print('🔍 Looking for order with ID: $id');
      print('📋 Available orders: ${_assignedOrders.length}');
      
      var results = _assignedOrders.where((order) => order.id.toString() == id);
      if (results.isNotEmpty) {
        print('✅ Found order by ID: ${results.first.orderNumber}');
        return results.first;
      }
      
      results = _assignedOrders.where((order) => order.orderNumber == id);
      if (results.isNotEmpty) {
        print('✅ Found order by order number: ${results.first.orderNumber}');
        return results.first;
      }
      
      results = _assignedOrders.where((order) => order.assignmentId == id);
      if (results.isNotEmpty) {
        print('✅ Found order by assignment ID: ${results.first.orderNumber}');
        return results.first;
      }
      
      print('❌ Order not found with ID: $id');
      return null;
    } catch (e) {
      print('❌ Error finding order: $e');
      return null;
    }
  }

  String getOrderStatus(String id) {
    final order = getOrderById(id);
    return order?.status ?? 'unknown';
  }

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

  void reset() {
    _assignedOrders = [];
    _availableOrders = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
