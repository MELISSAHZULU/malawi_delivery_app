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
import '../screens/seller/seller_home_screen.dart';
import '../screens/driver/driver_dashboard.dart';
import '../screens/shared/profile_screen.dart';

class AppNavigator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.buyerHome:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.sellerHome:
        return MaterialPageRoute(builder: (_) => const SellerHomeScreen());
      case AppRoutes.driverHome:
        return MaterialPageRoute(builder: (_) => const DriverDashboard());
      case AppRoutes.productDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: args?['productId'] ?? 0),
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
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

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
}
