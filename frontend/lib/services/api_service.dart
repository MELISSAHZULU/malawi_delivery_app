import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String baseUrl = AppConstants.apiBaseUrl;

  // ============ AUTH ============
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: 'access_token', value: data['access']);
        await _storage.write(key: 'refresh_token', value: data['refresh']);
        return {
          'success': true,
          'user': data['user'],
          'access': data['access'],
          'refresh': data['refresh'],
        };
      } else {
        String errorMsg = 'Login failed';
        if (data['error'] is String) {
          errorMsg = data['error'];
        } else if (data['error'] is Map) {
          errorMsg = data['error'].values.join(', ');
        } else if (data['detail'] is String) {
          errorMsg = data['detail'];
        } else if (data['message'] is String) {
          errorMsg = data['message'];
        }
        return {
          'success': false,
          'error': errorMsg,
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('Sending registration data: $userData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(userData),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data.containsKey('access')) {
          await _storage.write(key: 'access_token', value: data['access']);
          await _storage.write(key: 'refresh_token', value: data['refresh']);
        }
        return {
          'success': true,
          'user': data['user'],
          'access': data['access'] ?? '',
          'refresh': data['refresh'] ?? '',
        };
      } else {
        String errorMsg = 'Registration failed';
        if (data['error'] is String) {
          errorMsg = data['error'];
        } else if (data['error'] is Map) {
          errorMsg = data['error'].values.join(', ');
        } else if (data['detail'] is String) {
          errorMsg = data['detail'];
        } else if (data['message'] is String) {
          errorMsg = data['message'];
        }
        return {
          'success': false,
          'error': errorMsg,
        };
      }
    } catch (e) {
      print('Register error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ============ PRODUCTS ============
  Future<Map<String, dynamic>> getProducts() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/marketplace/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Get products status: ${response.statusCode}');
      print('Get products body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to fetch products'};
    } catch (e) {
      print('Get products error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSellerProducts() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/marketplace/seller/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get seller products status: ${response.statusCode}');
      print('Get seller products body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to fetch seller products'};
    } catch (e) {
      print('Get seller products error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/marketplace/seller/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(productData),
      );

      print('Create product status: ${response.statusCode}');
      print('Create product body: ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Failed to create product'};
      }
    } catch (e) {
      print('Create product error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ ORDERS ============
  Future<Map<String, dynamic>> getOrders() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get orders status: ${response.statusCode}');
      print('Get orders body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to fetch orders'};
    } catch (e) {
      print('Get orders error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get order status: ${response.statusCode}');
      print('Get order body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {'success': false, 'error': 'Order not found'};
      }
    } catch (e) {
      print('Get order error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(orderData),
      );

      print('Create order status: ${response.statusCode}');
      print('Create order body: ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Failed to create order'};
      }
    } catch (e) {
      print('Create order error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ USER ============
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'No token found'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get user status: ${response.statusCode}');
      print('Get user body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Session expired'};
      } else {
        return {'success': false, 'error': 'Failed to get user'};
      }
    } catch (e) {
      print('Get user error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
