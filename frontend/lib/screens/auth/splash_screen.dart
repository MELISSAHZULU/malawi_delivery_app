import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

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
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    
    // Reload user data
    await authProvider.loadUser();
    
    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      if (user != null) {
        String route;
        if (user.isBuyer) {
          route = AppRoutes.buyerHome;
        } else if (user.isSeller) {
          route = AppRoutes.sellerHome;
        } else if (user.isDriver) {
          route = AppRoutes.driverHome;
        } else {
          route = AppRoutes.buyerHome;
        }
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
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
            Text(
              'MalaWiDash',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0A1A2B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Malawi\'s Delivery Marketplace',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1A2B)),
            ),
          ],
        ),
      ),
    );
  }
}
