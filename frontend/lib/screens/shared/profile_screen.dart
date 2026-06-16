import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'John Doe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'john.doe@email.com',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            const Divider(),
            // Menu items
            _buildMenuItem(Icons.person_outline, 'Edit Profile', () {}),
            _buildMenuItem(Icons.history, 'Order History', () {}),
            _buildMenuItem(Icons.location_on, 'Saved Addresses', () {}),
            _buildMenuItem(Icons.payment, 'Payment Methods', () {}),
            _buildMenuItem(Icons.notifications_outlined, 'Notifications', () {}),
            _buildMenuItem(Icons.help_outline, 'Help & Support', () {}),
            const Divider(),
            _buildMenuItem(
              Icons.logout,
              'Logout',
              () {
                authProvider.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
