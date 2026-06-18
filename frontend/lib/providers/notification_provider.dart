import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NotificationProvider() {
    // Auto-fetch notifications when provider is created
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications();
      print('Fetch notifications response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _notifications = data
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
          print('Notifications loaded: ${_notifications.length}');
        } else {
          _notifications = [];
        }
      } else {
        _error = response['error'] ?? 'Failed to fetch notifications';
        print('Error loading notifications: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Network error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.markNotificationRead(notificationId);
      
      if (response['success'] == true) {
        // Update local state
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
          _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.markAllNotificationsRead();
      
      if (response['success'] == true) {
        // Update local state
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
