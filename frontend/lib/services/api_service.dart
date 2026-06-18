// Add this to your existing ApiService class
// Make sure the updateOrderStatus method uses the correct endpoint

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      
      print('Updating order $orderId to status: $status');
      
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      print('Update order status response: ${response.statusCode}');
      print('Update order status body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      }
      
      // Try to parse error message
      String errorMsg = 'Failed to update order status';
      try {
        final data = json.decode(response.body);
        errorMsg = data['error'] ?? data['detail'] ?? errorMsg;
      } catch (e) {
        // If response is not JSON, use status text
        errorMsg = response.reasonPhrase ?? errorMsg;
      }
      
      return {'success': false, 'error': errorMsg};
    } catch (e) {
      print('Update order status error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
