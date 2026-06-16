class AppConstants {
  static const String appName = 'MalaWiDash';
  static const String currency = 'MWK';
  static const double defaultDeliveryFee = 1500.0;
  static const Duration orderTimeout = Duration(minutes: 30);

  // API URLs - Update these to match your backend
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api';
  static const String wsBaseUrl = 'ws://127.0.0.1:8000/ws';

  // Storage Keys
  static const String userKey = 'user';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String offlineQueueKey = 'offline_queue';
  static const String cartKey = 'cart';
  static const String themeKey = 'theme';

  // Role-based navigation
  static const String buyerHome = '/buyer-home';
  static const String sellerHome = '/seller-home';
  static const String driverHome = '/driver-home';
}
