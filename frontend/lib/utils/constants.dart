class AppConstants {
  static const String apiBaseUrl = 'http://localhost:8000/api';
  static const String appName = 'MalaWiDash';
  static const String appVersion = '1.0.0';
  
  // Delivery fees
  static const double defaultDeliveryFee = 1500.0;
  
  // Payment methods
  static const List<String> paymentMethods = ['paychangu', 'cash'];
  
  // Order statuses
  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'picked_up',
    'driving',
    'arrived',
    'delivered',
    'cancelled'
  ];
  
  // Categories
  static const List<String> categories = ['FOOD', 'GROCERY', 'CRAFTS', 'MARKET'];
}
