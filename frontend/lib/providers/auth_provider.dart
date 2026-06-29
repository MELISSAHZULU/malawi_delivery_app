import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _token;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get token => _token;

  bool get isBuyer => _user?.role == 'buyer';
  bool get isSeller => _user?.role == 'seller';
  bool get isDriver => _user?.role == 'driver';
  
  String? get sellerAddress {
    if (_user == null || !_user!.isSeller) return null;
    return _user?.sellerAddress ?? _user?.location;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      print('Login response: $response');
      
      if (response['success'] == true) {
        _user = User.fromJson(response['user']);
        _token = response['access'];
        _isLoading = false;
        notifyListeners();
        
        print('✅ User logged in: ${_user?.username}, Role: ${_user?.role}');
        if (_user?.isDriver == true) {
          print('🚗 Vehicle: ${_user?.vehicleType} - ${_user?.vehiclePlate}');
        }
        
        return true;
      } else {
        _error = response['error'] ?? 'Login failed';
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

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(userData);
      print('Register response: $response');
      
      if (response['success'] == true) {
        _user = User.fromJson(response['user']);
        _token = response['access'];
        _isLoading = false;
        notifyListeners();
        print('✅ User registered: ${_user?.username}, Role: ${_user?.role}');
        return true;
      } else {
        _error = response['error'] ?? 'Registration failed';
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

  Future<void> loadUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      print('Load user response: $response');
      
      if (response['success'] == true) {
        _user = User.fromJson(response['data']);
        notifyListeners();
        print('✅ User loaded: ${_user?.username}, Role: ${_user?.role}');
        
        if (_user?.isDriver == true) {
          print('🚗 Vehicle: ${_user?.vehicleType} - ${_user?.vehiclePlate}');
          print('🆔 National ID: ${_user?.nationalId}');
        }
        if (_user?.isSeller == true) {
          print('🏪 Store: ${_user?.storeName}');
          print('📍 Address: ${_user?.sellerAddress}');
        }
      } else {
        print('❌ Failed to load user: ${response['error']}');
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
