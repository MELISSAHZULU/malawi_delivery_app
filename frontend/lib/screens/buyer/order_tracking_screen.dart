import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../../models/order.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.fetchOrders();
      
      if (orderProvider.orders.isNotEmpty) {
        // Get the most recent order
        final latestOrder = orderProvider.orders.first;
        // The order ID from the response is an integer, but we need to use the id field
        await orderProvider.trackOrder(latestOrder.id.toString());
        print('Tracking order: ${latestOrder.orderNumber} (ID: ${latestOrder.id})');
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _error = 'Failed to load orders';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final order = orderProvider.currentOrder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Live GPS Dispatch Loop'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0A1A2B),
        elevation: 0,
      ),
      body: _isLoading || orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? _buildEmptyState()
              : _buildTrackingContent(order, authProvider.user?.isSeller ?? false),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Active Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any active orders to track',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent(Order order, bool isSeller) {
    final progress = order.progress;
    final statusSteps = _getStatusSteps(order.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order: #${order.orderNumber}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${Formatters.orderStatusDisplay(order.status)}',
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF2A7DE1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.toStringAsFixed(0)}% Complete',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: statusSteps.map((step) {
                return _buildStatusStep(
                  step['label']!,
                  step['icon']!,
                  step['isComplete']!,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'DELIVERY ADDRESS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6478),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF2A7DE1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (order.items.isNotEmpty) ...[
            const Text(
              'ORDER ITEMS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.name}'),
                          Text(Formatters.currencyFormat(item.price * item.quantity)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getStatusSteps(String status) {
    final allSteps = [
      {'label': 'Paid', 'icon': Icons.payment},
      {'label': 'Cooking', 'icon': Icons.restaurant},
      {'label': 'Driving', 'icon': Icons.delivery_dining},
      {'label': 'Arrived', 'icon': Icons.location_on},
    ];

    final statusMap = {
      'pending': 0,
      'confirmed': 0,
      'preparing': 1,
      'ready': 1,
      'picked_up': 2,
      'driving': 2,
      'arrived': 3,
      'delivered': 3,
      'cancelled': -1,
    };

    final completedIndex = statusMap[status] ?? -1;
    
    return allSteps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      return {
        'label': step['label'],
        'icon': step['icon'],
        'isComplete': completedIndex >= index && completedIndex != -1,
      };
    }).toList();
  }

  Widget _buildStatusStep(String label, IconData icon, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isComplete ? const Color(0xFF0A1A2B) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isComplete ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  isComplete ? '✓ Complete' : 'In progress',
                  style: TextStyle(
                    color: isComplete ? Colors.green : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isComplete) const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.cyan;
      case 'picked_up':
        return Colors.teal;
      case 'driving':
        return Colors.indigo;
      case 'arrived':
        return Colors.lightBlue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
