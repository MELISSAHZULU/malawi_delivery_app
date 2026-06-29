import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';
import '../../utils/formatters.dart';
import 'edit_vehicle_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.fetchAssignedOrders();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);
    final user = authProvider.user;

    final assignedOrders = driverProvider.assignedOrders;
    final totalDeliveries = assignedOrders.length;
    final completedDeliveries = assignedOrders.where((o) => o.isDelivered).length;
    final totalEarnings = assignedOrders
        .where((o) => o.isDelivered)
        .fold(0.0, (sum, o) => sum + o.deliveryFee);

    // Get real driver data from user
    final String driverName = user?.username ?? 'Driver';
    final String driverEmail = user?.email ?? 'No email';
    final String driverPhone = user?.phoneNumber ?? 'Not provided';
    final String? profilePhotoUrl = user?.profilePhoto ?? user?.profilePicture;
    
    // Driver fields
    final String vehicleType = user?.vehicleType ?? 'Motorcycle';
    final String vehiclePlate = user?.vehiclePlate ?? 'Not specified';
    final String vehicleColor = user?.vehicleColor ?? 'Not specified';
    final String vehicleModel = user?.vehicleModel ?? 'Not specified';
    final String? vehicleImage = user?.vehicleImage;
    final String? nationalId = user?.nationalId;
    final String? nationalIdImage = user?.nationalIdImage;
    final String? driverLicense = user?.driverLicense;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Driver Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Photo or Initial
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange.shade100,
                    child: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              profilePhotoUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.delivery_dining,
                                  size: 50,
                                  color: Colors.orange.shade700,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.delivery_dining,
                            size: 50,
                            color: Colors.orange.shade700,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1A2B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    driverEmail,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  if (driverPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      driverPhone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🚚 Driver',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Driver',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$totalDeliveries',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A7DE1),
                          ),
                        ),
                        Text(
                          'Deliveries',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        Text(
                          'Rating',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          Formatters.currencyFormat(totalEarnings),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Earnings',
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
            const SizedBox(height: 16),

            // Vehicle Information with Edit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vehicle Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1A2B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditVehicleScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.edit, size: 16, color: Color(0xFF2A7DE1)),
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: Color(0xFF2A7DE1)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Vehicle Type', vehicleType),
                  _buildInfoRow('Plate Number', vehiclePlate),
                  _buildInfoRow('Vehicle Color', vehicleColor),
                  _buildInfoRow('Vehicle Model', vehicleModel),
                  if (vehicleImage != null && vehicleImage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(vehicleImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Identity Documents (if available)
            if (nationalId != null && nationalId.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identity Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1A2B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('National ID', nationalId),
                    if (nationalIdImage != null && nationalIdImage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(nationalIdImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (driverLicense != null && driverLicense.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(driverLicense),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Menu Items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.delivery_dining,
                    title: 'Delivery History',
                    subtitle: 'View all your deliveries',
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.deliveries);
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.attach_money,
                    title: 'Earnings',
                    subtitle: 'View your earnings history',
                    onTap: () {
                      _showEarningsDialog(context, totalEarnings, totalDeliveries);
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Delivery alerts, tips',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.notifications);
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Driver support, FAQs, and assistance',
                    onTap: () {
                      _showDriverHelpDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2A7DE1)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showEarningsDialog(BuildContext context, double totalEarnings, int totalDeliveries) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Total Earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.attach_money, size: 48, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              Formatters.currencyFormat(totalEarnings),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'From $totalDeliveries completed deliveries',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDriverHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Driver Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              icon: Icons.support_agent,
              title: 'Contact Support',
              subtitle: 'Reach out to our support team',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support chat coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildHelpItem(
              icon: Icons.help_outline,
              title: 'Frequently Asked Questions',
              subtitle: 'Common questions for drivers',
              onTap: () {
                Navigator.pop(context);
                _showDriverFAQDialog(context);
              },
            ),
            const Divider(height: 1),
            _buildHelpItem(
              icon: Icons.report_problem,
              title: 'Report an Issue',
              subtitle: 'Report delivery or app issues',
              onTap: () {
                Navigator.pop(context);
                _showReportIssueDialog(context);
              },
            ),
            const Divider(height: 1),
            _buildHelpItem(
              icon: Icons.directions_car,
              title: 'Delivery Guidelines',
              subtitle: 'Best practices for deliveries',
              onTap: () {
                Navigator.pop(context);
                _showDeliveryGuidelinesDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2A7DE1), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF0A1A2B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showDriverFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
                question: 'How do I accept a delivery?',
                answer: 'Go to the Deliveries screen and tap "Accept" on available orders.',
              ),
              const Divider(height: 1),
              _buildFAQItem(
                question: 'How do I navigate to the customer?',
                answer: 'Tap the "Navigate" button in the delivery details to open Google Maps.',
              ),
              const Divider(height: 1),
              _buildFAQItem(
                question: 'How are earnings calculated?',
                answer: 'Earnings are based on delivery fees. You earn MWK 1,500 per completed delivery.',
              ),
              const Divider(height: 1),
              _buildFAQItem(
                question: 'What if I have an issue with an order?',
                answer: 'Contact support through the Help & Support section.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0A1A2B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Report an Issue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the type of issue you\'re experiencing:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildIssueOption(
              icon: Icons.delivery_dining,
              title: 'Delivery Issue',
              subtitle: 'Problems with a delivery',
            ),
            const Divider(height: 1),
            _buildIssueOption(
              icon: Icons.payment,
              title: 'Payment Issue',
              subtitle: 'Payment or earnings problem',
            ),
            const Divider(height: 1),
            _buildIssueOption(
              icon: Icons.bug_report,
              title: 'App Issue',
              subtitle: 'Technical or app problem',
            ),
            const Divider(height: 1),
            _buildIssueOption(
              icon: Icons.people,
              title: 'Customer Issue',
              subtitle: 'Problem with a customer',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you! Our team will review your report.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A7DE1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2A7DE1), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0A1A2B),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryGuidelinesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delivery Guidelines',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuidelineItem(
                icon: Icons.check_circle,
                text: 'Always arrive on time for pickup',
                color: Colors.green,
              ),
              const Divider(height: 1),
              _buildGuidelineItem(
                icon: Icons.phone,
                text: 'Contact the customer before arrival',
                color: Colors.blue,
              ),
              const Divider(height: 1),
              _buildGuidelineItem(
                icon: Icons.handshake,
                text: 'Be polite and professional',
                color: Colors.purple,
              ),
              const Divider(height: 1),
              _buildGuidelineItem(
                icon: Icons.note,
                text: 'Verify the order before handing over',
                color: Colors.orange,
              ),
              const Divider(height: 1),
              _buildGuidelineItem(
                icon: Icons.rate_review,
                text: 'Ask for rating after delivery',
                color: Colors.amber,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0A1A2B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              driverProvider.reset();
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
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
