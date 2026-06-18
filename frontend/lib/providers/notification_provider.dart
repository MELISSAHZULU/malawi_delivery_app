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

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications();
      
      if (response['success'] == true) {
        _notifications = (response['data'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
      } else {
        _error = response['error'] ?? 'Failed to fetch notifications';
      }
    } catch (e) {
      _error = 'Network error: $e';
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
