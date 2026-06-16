// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:malawi_delivery/providers/auth_provider.dart';
import 'package:malawi_delivery/providers/cart_provider.dart';
import 'package:malawi_delivery/providers/order_provider.dart';
import 'package:malawi_delivery/providers/offline_queue_provider.dart';
import 'package:malawi_delivery/routes/app_routes.dart';
import 'package:malawi_delivery/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('offlineQueue');
  await Hive.openBox('userData');
  await Hive.openBox('cartBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => OfflineQueueProvider()),
      ],
      child: MaterialApp(
        title: 'MalaWiDash',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}