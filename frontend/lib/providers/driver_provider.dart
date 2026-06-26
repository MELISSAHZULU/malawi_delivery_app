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
      print('📦 Fetch driver orders raw response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        print('📦 Data type: ${data.runtimeType}');
        
        if (data is List) {
          print('📦 Data is a list with ${data.length} items');
          
          _assignedOrders = [];
          for (var item in data) {
            try {
              print('📦 Processing item with keys: ${item.keys}');
              
              Map<String, dynamic> orderData = {};
              
              item.forEach((key, value) {
                orderData[key] = value;
              });
              
              orderData['order_number'] = item['order_number'];
              orderData['status'] = item['status'];
              orderData['total'] = item['total_amount'];
              orderData['delivery_fee'] = item['delivery_fee'];
              orderData['items'] = item['items'] ?? [];
              orderData['driver_name'] = item['driver_name'];
              orderData['driver_phone'] = item['driver_phone'];
              orderData['seller_name'] = item['seller_name'];
              orderData['seller_address'] = item['seller_address'];
              orderData['delivery_address'] = item['delivery_address'];
              orderData['delivery_instructions'] = item['delivery_instructions'] ?? '';
              orderData['customer_name'] = 'Customer';
              orderData['customer_phone'] = item['customer_phone'] ?? '';
              orderData['assignment_id'] = item['id']?.toString();
              
              if (item['status'] != null) {
                orderData['assignment_status'] = item['status'].toString();
              }
              
              print('📦 Created order data: ${orderData['order_number']}, Status: ${orderData['status']}');
              
              _assignedOrders.add(Order.fromJson(orderData));
            } catch (e) {
              print('❌ Error parsing order: $e');
            }
          }
          
          print('✅ Driver orders loaded: ${_assignedOrders.length}');
        } else {
          print('⚠️ Data is not a list: ${data.runtimeType}');
          _assignedOrders = [];
        }
      } else {
        _error = response['error'] ?? 'Failed to fetch driver orders';
        print('❌ Error loading driver orders: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAvailableOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAvailableOrders();
      print('📦 Fetch available orders raw response: $response');
      
      _availableOrders = [];
      
      // getAvailableOrders always returns Map<String, dynamic>
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          for (var item in data) {
            try {
              final order = Order.fromJson(item as Map<String, dynamic>);
              _availableOrders.add(order);
            } catch (e) {
              print('❌ Error parsing available order: $e');
            }
          }
          print('✅ Available orders loaded: ${_availableOrders.length}');
        } else {
          print('⚠️ Data is not a list: ${data.runtimeType}');
        }
      } else {
        _error = response['error'] ?? 'Failed to fetch available orders';
        print('❌ Error loading available orders: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Network error fetching available orders: $e');
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
      print('📦 Accept delivery response: $response');
      
      if (response['success'] == true) {
        await fetchAssignedOrders();
        await fetchAvailableOrders();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to accept delivery';
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDeliveryStatus(String orderId, String action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateDeliveryStatus(orderId, action);
      print('📦 Update delivery status response: $response');
      
      if (response['success'] == true) {
        await fetchAssignedOrders();
        await fetchAvailableOrders();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to update delivery status';
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Order? getOrderById(String id) {
    try {
      print('🔍 Looking for order with ID: $id');
      print('📋 Available orders: ${_assignedOrders.length}');
      
      for (var order in _assignedOrders) {
        if (order.id.toString() == id || order.orderNumber == id || order.assignmentId == id) {
          print('✅ Found order: ${order.orderNumber}');
          return order;
        }
      }
      
      print('❌ Order not found with ID: $id');
      return null;
    } catch (e) {
      print('❌ Error finding order: $e');
      return null;
    }
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
