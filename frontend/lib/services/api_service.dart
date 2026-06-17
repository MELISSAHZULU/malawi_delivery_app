// Add these methods to your existing ApiService class

// Get weekly earnings for seller
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

// Update product
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
        'Authorization': 'Bearer $token',
      },
      body: json.encode(productData),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': json.decode(response.body)};
    }
    return {'success': false, 'error': 'Failed to update product'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

// Delete product
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
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204) {
      return {'success': true};
    }
    return {'success': false, 'error': 'Failed to delete product'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

// Update order status
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
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status}),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': json.decode(response.body)};
    }
    return {'success': false, 'error': 'Failed to update order status'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
