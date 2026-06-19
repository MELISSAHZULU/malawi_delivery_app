import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order.dart';

class DriverProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Order> _assignedOrders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get assignedOrders => _assignedOrders;
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
              return Order.fromJson(item);
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

  Future<bool> updateDeliveryStatus(String orderId, String action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateDeliveryStatus(orderId, action);
      print('Update delivery status response: $response');
      
      if (response['success'] == true) {
        await fetchAssignedOrders();
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
