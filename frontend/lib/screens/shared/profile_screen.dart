import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  int _orderCount = 0;
  int _productCount = 0;
  double _rating = 0.0;
  int _totalDeliveries = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      // Fetch orders
      await orderProvider.fetchOrders();
      final orders = orderProvider.orders;
      
      // Reset values
      _orderCount = 0;
      _productCount = 0;
      _rating = 0.0;
      _totalDeliveries = 0;
      _totalEarnings = 0.0;

      // Fetch products (if seller)
      if (user?.isSeller == true) {
        await productProvider.fetchSellerProducts();
        _productCount = productProvider.products.length;
      }

      // Calculate stats based on user role
      if (user != null) {
        if (user.isBuyer) {
          _orderCount = orders.length;
        } else if (user.isSeller) {
          _orderCount = orders.length;
          _totalEarnings = orders
              .where((o) => o.status == 'delivered' || o.status == 'completed')
              .fold(0.0, (sum, order) => sum + (order.total ?? 0));
          if (_orderCount > 0) {
            _rating = 4.5;
          }
        } else if (user.isDriver) {
          _totalDeliveries = orders
              .where((o) => o.status == 'delivered' || o.status == 'completed')
              .length;
          _totalEarnings = orders
              .where((o) => o.status == 'delivered' || o.status == 'completed')
              .fold(0.0, (sum, order) => sum + (order.deliveryFee ?? 0));
          if (_totalDeliveries > 0) {
            _rating = 4.8;
          }
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0A1A2B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile header
                  _buildProfileHeader(user),
                  const SizedBox(height: 16),

                  // Stats Cards - Role specific with real data
                  _buildStatsCards(user),
                  const SizedBox(height: 16),

                  // Menu Items - Role specific
                  const Divider(),
                  _buildMenuItems(user, context),
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

  Widget _buildProfileHeader(User user) {
    return Container(
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
            child: user.profilePicture != null
                ? ClipOval(
                    child: Image.network(
                      user.profilePicture!,
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
            user.username,
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
              color: _getRoleColor(user.role),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getRoleDisplay(user.role),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.phoneNumber!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
          if (user.isVerified == true) ...[
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
          if (user.isSeller && user.storeName != null) ...[
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
                          'Store: ${user.storeName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (user.location != null && user.location!.isNotEmpty)
                          Text(
                            user.location!,
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
          // Driver info
          if (user.isDriver) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Available for deliveries',
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
    );
  }

  Widget _buildStatsCards(User user) {
    if (user.isSeller) {
      return Row(
        children: [
          _buildStatCard('Products', '$_productCount', Icons.inventory_2),
          _buildStatCard('Orders', '$_orderCount', Icons.shopping_bag),
          _buildStatCard('Rating', '${_rating.toStringAsFixed(1)} ★', Icons.star),
        ],
      );
    } else if (user.isDriver) {
      return Row(
        children: [
          _buildStatCard('Deliveries', '$_totalDeliveries', Icons.delivery_dining),
          _buildStatCard('Rating', '${_rating.toStringAsFixed(1)} ★', Icons.star),
          _buildStatCard('Earnings', 'MWK ${_totalEarnings.toStringAsFixed(0)}', Icons.attach_money),
        ],
      );
    } else {
      // Buyer (default)
      return Row(
        children: [
          _buildStatCard('Orders', '$_orderCount', Icons.shopping_bag),
          _buildStatCard('Wishlist', '0', Icons.favorite),
          _buildStatCard('Saved', '0', Icons.bookmark),
        ],
      );
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
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

  Widget _buildMenuItems(User user, BuildContext context) {
    List<Widget> menuItems = [];

    // Common menu items for all users
    menuItems.add(_buildMenuItem(
      Icons.history,
      'Order History',
      () => Navigator.pushReplacementNamed(context, AppRoutes.orderHistory),
    ));

    // Buyer-specific menu items
    if (user.isBuyer) {
      menuItems.add(_buildMenuItem(
        Icons.location_on_outlined,
        'Saved Addresses',
        () => Navigator.pushNamed(context, AppRoutes.savedAddresses),
      ));
      menuItems.add(_buildMenuItem(
        Icons.payment_outlined,
        'Payment Methods',
        () => Navigator.pushNamed(context, AppRoutes.paymentMethods),
      ));
    }

    // Seller-specific menu items
    if (user.isSeller) {
      menuItems.add(_buildMenuItem(
        Icons.inventory_2,
        'Manage Products',
        () => Navigator.pushNamed(context, AppRoutes.manageProducts),
      ));
      menuItems.add(_buildMenuItem(
        Icons.storefront,
        'Store Settings',
        () => Navigator.pushNamed(context, AppRoutes.storeSettings),
      ));
      menuItems.add(_buildMenuItem(
        Icons.analytics,
        'Sales Analytics',
        () => Navigator.pushNamed(context, AppRoutes.salesAnalytics),
      ));
    }

    // Driver-specific menu items
    if (user.isDriver) {
      menuItems.add(_buildMenuItem(
        Icons.route,
        'Delivery History',
        () => Navigator.pushNamed(context, AppRoutes.deliveries),
      ));
      menuItems.add(_buildMenuItem(
        Icons.attach_money,
        'Earnings',
        () => {},
      ));
    }

    // Common menu items for all users
    menuItems.add(_buildMenuItem(
      Icons.notifications_outlined,
      'Notifications',
      () => Navigator.pushNamed(context, AppRoutes.notifications),
    ));
    menuItems.add(_buildMenuItem(
      Icons.help_outline,
      'Help & Support',
      () => Navigator.pushNamed(context, AppRoutes.helpSupport),
    ));

    // Logout
    menuItems.add(
      _buildMenuItem(
        Icons.logout,
        'Logout',
        () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Are you sure you want to logout?',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context, true);
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        isDestructive: true,
      ),
    );

    return Column(children: menuItems);
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
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
