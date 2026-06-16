import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    child: user?.profilePicture != null
                        ? ClipOval(
                            child: Image.network(
                              user!.profilePicture!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade600,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade600,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.username ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1A2B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user?.role ?? 'buyer'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleDisplay(user?.role ?? 'buyer'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  if (user?.phoneNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.phoneNumber!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (user?.isVerified == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Account',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Seller store info
                  if (user?.isSeller == true && user?.storeName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store, color: Color(0xFF2A7DE1)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Store: ${user?.storeName ?? 'No store'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (user?.location != null)
                                  Text(
                                    user!.location!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Cards
            if (user?.isSeller == true) ...[
              Row(
                children: [
                  _buildStatCard('Products', '12', Icons.inventory_2),
                  _buildStatCard('Orders', '156', Icons.shopping_bag),
                  _buildStatCard('Rating', '4.8 ★', Icons.star),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (user?.isDriver == true) ...[
              Row(
                children: [
                  _buildStatCard('Deliveries', '89', Icons.delivery_dining),
                  _buildStatCard('Rating', '4.9 ★', Icons.star),
                  _buildStatCard('Earnings', 'MWK 487K', Icons.attach_money),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (user?.isBuyer == true) ...[
              Row(
                children: [
                  _buildStatCard('Orders', '23', Icons.shopping_bag),
                  _buildStatCard('Wishlist', '8', Icons.favorite),
                  _buildStatCard('Saved', '4', Icons.bookmark),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Menu Items
            const Divider(),
            _buildMenuItem(
              Icons.history,
              'Order History',
              () => Navigator.pushNamed(context, AppRoutes.orderHistory),
            ),
            _buildMenuItem(
              Icons.location_on_outlined,
              'Saved Addresses',
              () => Navigator.pushNamed(context, AppRoutes.savedAddresses),
            ),
            _buildMenuItem(
              Icons.payment_outlined,
              'Payment Methods',
              () => Navigator.pushNamed(context, AppRoutes.paymentMethods),
            ),
            _buildMenuItem(
              Icons.notifications_outlined,
              'Notifications',
              () => Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            _buildMenuItem(
              Icons.help_outline,
              'Help & Support',
              () => Navigator.pushNamed(context, AppRoutes.helpSupport),
            ),
            const Divider(),
            _buildMenuItem(
              Icons.logout,
              'Logout',
              () async {
                // Show logout confirmation
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                }
              },
              isDestructive: true,
            ),
            const SizedBox(height: 16),

            // App version
            Center(
              child: Text(
                'MalaWiDash v1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF2A7DE1), size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF0A1A2B),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'buyer':
        return Colors.blue.shade700;
      case 'seller':
        return Colors.green.shade700;
      case 'driver':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'buyer':
        return '👤 Customer';
      case 'seller':
        return '🏪 Vendor';
      case 'driver':
        return '🚚 Driver';
      default:
        return role;
    }
  }
}
