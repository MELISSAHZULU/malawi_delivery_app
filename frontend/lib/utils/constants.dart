class AppConstants {
  static const String appName = 'MalaWiDash';
  static const String currency = 'MWK';
  static const double defaultDeliveryFee = 1500.0;
  static const Duration orderTimeout = Duration(minutes: 30);

  // API URLs - UPDATE THESE WITH YOUR BACKEND URL
  static const String apiBaseUrl = 'https://your-api-url.com/api';
  static const String wsBaseUrl = 'wss://your-api-url.com/ws';

  // Storage Keys
  static const String userKey = 'user';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String offlineQueueKey = 'offline_queue';
  static const String cartKey = 'cart';
  static const String themeKey = 'theme';

  // Order Statuses
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
  static const List<String> categories = [
    'ALL ITEMS',
    'FOOD',
    'GROCERY',
    'CRAFTS',
    'MARKET'
  ];
}
