import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import 'login_screen.dart';
import '../buyer/home_screen.dart';
import '../seller/seller_home_screen.dart';
import '../driver/driver_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for auth to load
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    print('🔍 SplashScreen - Checking auth...');
    print('🔍 Is authenticated: ${authProvider.isAuthenticated}');
    print('🔍 User: ${user?.username}, Role: ${user?.role}');
    
    // Determine the route based on role
    String route;
    if (authProvider.isAuthenticated && user != null) {
      if (user.isBuyer) {
        route = AppRoutes.buyerHome;
        print('👤 Navigating to Buyer Home');
      } else if (user.isSeller) {
        route = AppRoutes.sellerHome;
        print('🏪 Navigating to Seller Home');
      } else if (user.isDriver) {
        route = AppRoutes.driverHome;
        print('🚚 Navigating to Driver Dashboard');
      } else {
        route = AppRoutes.buyerHome;
      }
    } else {
      route = AppRoutes.login;
      print('🔓 Navigating to Login');
    }
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Mala', style: TextStyle(color: Color(0xFF0A1A2B))),
                  TextSpan(text: 'Wi', style: TextStyle(color: Color(0xFF2A7DE1))),
                  TextSpan(text: 'Dash', style: TextStyle(color: Color(0xFF0A1A2B))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Malawi\'s Local Delivery Marketplace',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Color(0xFF2A7DE1),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
