import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../utils/formatters.dart';
import '../../routes/app_routes.dart';

class DriverDeliveriesScreen extends StatefulWidget {
  const DriverDeliveriesScreen({Key? key}) : super(key: key);

  @override
  State<DriverDeliveriesScreen> createState() => _DriverDeliveriesScreenState();
}

class _DriverDeliveriesScreenState extends State<DriverDeliveriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeliveries();
    });
  }

  Future<void> _loadDeliveries() async {
    await Provider.of<DriverProvider>(context, listen: false).fetchAssignedOrders();
  }

  double? _calculateDistance(double? lat1, double? lon1, double? lat2, double? lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final deliveries = driverProvider.assignedOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Deliveries'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
            color: Colors.black,
          ),
        ],
      ),
      body: driverProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : deliveries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delivery_dining_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No deliveries assigned',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll see deliveries here when assigned',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDeliveries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: deliveries.length,
                    itemBuilder: (context, index) {
                      return _buildDeliveryCard(deliveries[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildDeliveryCard(dynamic order) {
    final status = order.status?.toLowerCase() ?? 'pending';

    final isPending = status == 'pending' || status == 'accepted' ||
        status == 'confirmed' || status == 'ready' || status == 'preparing';
    final isPickedUp = status == 'picked_up';
    final isDriving = status == 'driving';
    final isDelivered = status == 'delivered' || status == 'completed';
    
    final storeName = order.sellerName ?? 'Store';
    final storeAddress = order.sellerAddress ?? 'Pickup location';
    final deliveryAddress = order.deliveryAddress ?? 'Delivery location';
    final driverFee = order.deliveryFee ?? 0;
    final orderNumber = order.orderNumber ?? 'Order #${order.id ?? ''}';

    final distance = _calculateDistance(
      order.sellerLatitude,
      order.sellerLongitude,
      order.deliveryLatitude,
      order.deliveryLongitude,
    );

    int itemCount = 0;
    try {
      if (order.items != null && order.items is List) itemCount = order.items.length;
    } catch (_) {}

    Color getStatusColor() {
      if (isDelivered) return Colors.green;
      if (isDriving || isPickedUp) return Colors.blue;
      if (isPending) return Colors.orange;
      return Colors.grey;
    }

    String getStatusDisplay() {
      if (isDelivered) return 'Delivered';
      if (isDriving) return 'In Transit';
      if (isPickedUp) return 'Picked Up';
      if (isPending) return 'Ready for Pickup';
      return status.replaceAll('_', ' ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getStatusDisplay().toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: getStatusColor()),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Progress steps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildProgressSteps(status),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.storefront_outlined, size: 20, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pickup', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(storeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(
                            storeAddress,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Dotted line connector
                Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: Column(
                    children: List.generate(3, (_) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      width: 2,
                      height: 4,
                      color: Colors.grey.shade300,
                    )),
                  ),
                ),

                // Delivery location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.location_on_outlined, size: 20, color: Colors.green.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            deliveryAddress,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Distance and Driver Fee
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.route_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              distance != null
                                  ? '${distance.toStringAsFixed(1)} km'
                                  : 'N/A',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Formatters.currencyFormat(driverFee),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                  ),
                                  Text(
                                    'Your fee',
                                    style: TextStyle(fontSize: 10, color: Colors.green.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (itemCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '$itemCount item${itemCount > 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Show "Complete Delivery" for driving orders
                if (isDriving)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeliveryCompleteDialog(context, order),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Complete Delivery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                // Show "Pick Up Order" for picked up or pending orders
                else if (isPickedUp || isPending)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPickupDialog(context, order),
                      icon: const Icon(Icons.shopping_bag, size: 18),
                      label: const Text('Pick Up Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1A2B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                // Show "Completed" for delivered orders
                else if (isDelivered)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                
                // Details button - PASS THE ORDER PROPERLY
                OutlinedButton.icon(
                  onPressed: () {
                    // Pass the entire order data
                    Navigator.pushNamed(
                      context,
                      AppRoutes.deliveryDetail,
                      arguments: order, // Pass the order object directly
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A1A2B),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(String status) {
    final steps = ['pending', 'picked_up', 'delivered'];
    final labels = ['Pending', 'Picked Up', 'Delivered'];

    int currentStep = 0;
    if (status == 'picked_up') currentStep = 1;
    if (status == 'driving') currentStep = 1;
    if (status == 'delivered') currentStep = 2;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final filled = (i ~/ 2) < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? Colors.green : Colors.grey.shade300,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? const Color(0xFF0A1A2B)
                        : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : _stepIcon(stepIndex),
                size: 14,
                color: (isCompleted || isActive) ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF0A1A2B) : Colors.grey,
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _stepIcon(int index) {
    switch (index) {
      case 0: return Icons.receipt_outlined;
      case 1: return Icons.shopping_bag_outlined;
      case 2: return Icons.check_circle_outline;
      default: return Icons.circle_outlined;
    }
  }

  void _showPickupDialog(BuildContext context, dynamic order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pickup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ready to pick up this order from the seller?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 ${order.sellerName ?? 'Store'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Order: ${order.orderNumber ?? '#'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              final success = await driverProvider.updateDeliveryStatus(
                order.id.toString(),
                'pick_up',
              );
              messenger.showSnackBar(SnackBar(
                content: Text(success ? '✅ Order picked up successfully' : '❌ ${driverProvider.error ?? 'Failed'}'),
                backgroundColor: success ? Colors.green : Colors.red,
              ));
              if (success && mounted) {
                await _loadDeliveries();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1A2B), foregroundColor: Colors.white),
            child: const Text('Pick Up'),
          ),
        ],
      ),
    );
  }

  void _showDeliveryCompleteDialog(BuildContext context, dynamic order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm delivery to the customer?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 ${order.deliveryAddress ?? 'Delivery address'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Order: ${order.orderNumber ?? '#'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              final success = await driverProvider.updateDeliveryStatus(
                order.id.toString(),
                'deliver',
              );
              messenger.showSnackBar(SnackBar(
                content: Text(success ? '✅ Delivery completed! 🎉' : '❌ ${driverProvider.error ?? 'Failed'}'),
                backgroundColor: success ? Colors.green : Colors.red,
              ));
              if (success && mounted) {
                await _loadDeliveries();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
