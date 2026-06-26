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

  Future<void> logout() async {
    await _storage.deleteAll();
  }

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

  Future<Map<String, dynamic>> updateStore(Map<String, dynamic> storeData) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/auth/update-store/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(storeData),
      );

      print('Update store status: ${response.statusCode}');
      print('Update store body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true, 
          'data': data,
          'user': data['user'] ?? null
        };
      }
      return {'success': false, 'error': 'Failed to update store'};
    } catch (e) {
      print('Update store error: $e');
      return {'success': false, 'error': e.toString()};
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

  Future<Map<String, dynamic>> updateProduct(int productId, Map<String, dynamic> productData) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/marketplace/seller/products/$productId/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(productData),
      );

      print('Update product status: ${response.statusCode}');
      print('Update product body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Failed to update product'};
    } catch (e) {
      print('Update product error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.delete(
        Uri.parse('$baseUrl/marketplace/seller/products/$productId/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete product status: ${response.statusCode}');
      print('Delete product body: ${response.body}');

      if (response.statusCode == 204) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Failed to delete product'};
    } catch (e) {
      print('Delete product error: $e');
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

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      print('Update order status: ${response.statusCode}');
      print('Update order body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Failed to update order status'};
    } catch (e) {
      print('Update order status error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWeeklyEarnings() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/weekly-earnings/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get weekly earnings status: ${response.statusCode}');
      print('Get weekly earnings body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Failed to fetch weekly earnings'};
    } catch (e) {
      print('Get weekly earnings error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ NOTIFICATIONS ============
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get notifications status: ${response.statusCode}');
      print('Get notifications body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to fetch notifications'};
    } catch (e) {
      print('Get notifications error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(int notificationId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/mark-read/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Mark notification read status: ${response.statusCode}');
      print('Mark notification read body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Failed to mark notification as read'};
    } catch (e) {
      print('Mark notification read error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Mark all notifications read status: ${response.statusCode}');
      print('Mark all notifications read body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Failed to mark all as read'};
    } catch (e) {
      print('Mark all notifications read error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ PAYMENTS ============
  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/payments/status/$orderId/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get payment status: ${response.statusCode}');
      print('Get payment status body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Failed to get payment status'};
    } catch (e) {
      print('Get payment status error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ DRIVER ============
  Future<Map<String, dynamic>> getDriverOrders() async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/orders/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get driver orders status: ${response.statusCode}');
      print('Get driver orders body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': 'Failed to fetch driver orders'};
    } catch (e) {
      print('Get driver orders error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> acceptDelivery(int orderId) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/accept/$orderId/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Accept delivery response: ${response.statusCode}');
      print('Accept delivery body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Failed to accept delivery'};
    } catch (e) {
      print('Accept delivery error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateDeliveryStatus(String orderId, String action) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/orders/$orderId/status/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'action': action}),
      );

      print('Update delivery status response: ${response.statusCode}');
      print('Update delivery status body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Failed to update delivery status'};
    } catch (e) {
      print('Update delivery status error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAvailableOrders() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/delivery/available/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get available orders status: ${response.statusCode}');
      print('Get available orders body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle both plain list and wrapped response
        if (data is List) {
          return {'success': true, 'data': data};
        } else if (data is Map<String, dynamic>) {
          // If it's already a map with success, return it
          if (data.containsKey('success')) {
            return data;
          }
          // Otherwise wrap it
          return {'success': true, 'data': data};
        } else {
          return {'success': true, 'data': data};
        }
      }
      return {'success': false, 'error': 'Failed to fetch available orders'};
    } catch (e) {
      print('Get available orders error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
