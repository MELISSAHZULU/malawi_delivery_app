import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/buyer/home_screen.dart';
import '../screens/buyer/product_detail_screen.dart';
import '../screens/buyer/cart_screen.dart';
import '../screens/buyer/checkout_screen.dart';
import '../screens/buyer/order_tracking_screen.dart';
import '../screens/buyer/order_history_screen.dart';
import '../screens/buyer/buyer_profile_screen.dart';
import '../screens/seller/seller_home_screen.dart';
import '../screens/seller/add_product_screen.dart';
import '../screens/seller/edit_product_screen.dart';
import '../screens/seller/edit_shop_profile_screen.dart';
import '../screens/seller/manage_products_screen.dart';
import '../screens/seller/store_settings_screen.dart';
import '../screens/seller/sales_analytics_screen.dart';
import '../screens/driver/driver_dashboard.dart';
import '../screens/driver/driver_profile_screen.dart';
import '../screens/driver/driver_deliveries_screen.dart';
import '../screens/driver/delivery_detail_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/help_support_screen.dart';
import '../screens/shared/saved_addresses_screen.dart';
import '../screens/shared/payment_methods_screen.dart';
import '../screens/shared/profile_screen.dart';

class AppNavigator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ==================== AUTH SCREENS ====================
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // ==================== BUYER SCREENS ====================
      case AppRoutes.buyerHome:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case AppRoutes.productDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productId: args?['productId'] ?? 0,
          ),
        );
      
      case AppRoutes.cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      
      case AppRoutes.checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      
      case AppRoutes.tracking:
        final orderId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        );
      
      case AppRoutes.orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());
      
      case AppRoutes.buyerProfile:
        return MaterialPageRoute(builder: (_) => const BuyerProfileScreen());

      // ==================== SELLER SCREENS ====================
      case AppRoutes.sellerHome:
        return MaterialPageRoute(builder: (_) => const SellerHomeScreen());
      
      case AppRoutes.addProduct:
        return MaterialPageRoute(builder: (_) => const AddProductScreen());
      
      case AppRoutes.editProduct:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EditProductScreen(
            productId: args?['productId'] ?? 0,
          ),
        );
      
      case AppRoutes.editShopProfile:
        return MaterialPageRoute(builder: (_) => const EditShopProfileScreen());
      
      case AppRoutes.manageProducts:
        return MaterialPageRoute(builder: (_) => const ManageProductsScreen());
      
      case AppRoutes.storeSettings:
        return MaterialPageRoute(builder: (_) => const StoreSettingsScreen());
      
      case AppRoutes.salesAnalytics:
        return MaterialPageRoute(builder: (_) => const SalesAnalyticsScreen());

      // ==================== DRIVER SCREENS ====================
      case AppRoutes.driverHome:
        return MaterialPageRoute(builder: (_) => const DriverDashboard());
      
      case AppRoutes.driverProfile:
        return MaterialPageRoute(builder: (_) => const DriverProfileScreen());
      
      case AppRoutes.deliveries:
        return MaterialPageRoute(builder: (_) => const DriverDeliveriesScreen());
      
      case AppRoutes.deliveryDetail:
        // ✅ FIXED: Extract arguments and pass to constructor
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => DeliveryDetailScreen(order: args),
          settings: settings,
        );
      
      case AppRoutes.driverTracking:
        final orderId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        );

      // ==================== SHARED SCREENS ====================
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());
      
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      
      case AppRoutes.helpSupport:
        return MaterialPageRoute(builder: (_) => const HelpSupportScreen());
      
      case AppRoutes.savedAddresses:
        return MaterialPageRoute(builder: (_) => const SavedAddressesScreen());
      
      case AppRoutes.paymentMethods:
        return MaterialPageRoute(builder: (_) => const PaymentMethodsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Page not found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
        );
    }
  }

  // ==================== NAVIGATION HELPERS ====================
  
  static Future<T?> push<T>(BuildContext context, String routeName,
      {dynamic arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static Future<T?> pushReplacement<T>(BuildContext context, String routeName,
      {dynamic arguments}) {
    return Navigator.pushReplacementNamed(context, routeName,
        arguments: arguments);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  static void pushAndRemoveUntil(BuildContext context, String routeName,
      {dynamic arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void popWithResult<T>(BuildContext context, T result) {
    Navigator.pop(context, result);
  }

  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }

  static void maybePop(BuildContext context) {
    Navigator.maybePop(context);
  }
}
