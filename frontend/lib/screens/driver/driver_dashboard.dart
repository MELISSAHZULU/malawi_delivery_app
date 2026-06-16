import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Availability',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: const Color(0xFF1F8B4C),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Assigned deliveries
            const Text(
              'Assigned Deliveries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.delivery_dining),
                      title: Text('Order #MW-${2840 + index}'),
                      subtitle: Text('Pickup: Chambo & Nsima Hub'),
                      trailing: Chip(
                        label: Text(index == 0 ? 'Active' : 'Pending'),
                        backgroundColor: index == 0 ? Colors.green : Colors.orange,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.sellerDashboard);
          }
        },
      ),
    );
  }
}
