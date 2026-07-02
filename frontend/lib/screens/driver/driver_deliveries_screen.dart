import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../models/order.dart';
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
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.fetchAssignedOrders();
    await driverProvider.fetchAvailableOrders(); // ✅ ALSO FETCH AVAILABLE ORDERS
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
    final assignedOrders = driverProvider.assignedOrders;
    final availableOrders = driverProvider.availableOrders;

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
          : RefreshIndicator(
              onRefresh: _loadDeliveries,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ✅ Available Orders Section (Ready for pickup)
                  if (availableOrders.isNotEmpty) ...[
                    const Text(
                      '📦 Available for Pickup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1A2B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...availableOrders.map((order) => _buildAvailableOrderCard(order)),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  // ✅ Assigned Orders Section
                  if (assignedOrders.isNotEmpty) ...[
                    const Text(
                      '🚚 My Deliveries',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1A2B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...assignedOrders.map((order) => _buildDeliveryCard(order)),
                  ],

                  // Empty state
                  if (availableOrders.isEmpty && assignedOrders.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delivery_dining_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No deliveries',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for available orders',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ✅ Available Order Card - Shows orders ready for pickup
  Widget _buildAvailableOrderCard(Order order) {
    final storeName = order.sellerName ?? 'Store';
    final storeAddress = order.sellerAddress ?? 'Pickup location';
    final driverFee = order.deliveryFee ?? 0;
    final orderNumber = order.orderNumber ?? 'Order #${order.id ?? ''}';
    final total = order.total ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        storeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'READY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  orderNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.storefront_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        storeAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Earnings: ${Formatters.currencyFormat(driverFee)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Total: ${Formatters.currencyFormat(total)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0A1A2B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await driverProvider.acceptDelivery(
                        int.parse(order.id),
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? '✅ Order accepted! 🚚' : '❌ ${driverProvider.error ?? 'Failed to accept'}',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) {
                        await _loadDeliveries();
                      }
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Accept Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A1A2B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Delivery Card - Shows assigned deliveries
  Widget _buildDeliveryCard(Order order) {
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

    int itemCount = order.items.length;

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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
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
                              distance != null ? '${distance.toStringAsFixed(1)} km' : 'N/A',
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
                if (!isDelivered) ...[
                  const SizedBox(height: 12),
                  if (isDriving)
                    ElevatedButton.icon(
                      onPressed: () => _showDeliveryCompleteDialog(context, order),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Complete Delivery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else if (isPickedUp || isPending)
                    ElevatedButton.icon(
                      onPressed: () => _showPickupDialog(context, order),
                      icon: const Icon(Icons.shopping_bag, size: 18),
                      label: const Text('Pick Up Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1A2B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
                if (isDelivered)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final orderData = order.toJson();
                    Navigator.pushNamed(
                      context,
                      AppRoutes.deliveryDetail,
                      arguments: orderData,
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A1A2B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  void _showPickupDialog(BuildContext context, Order order) {
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

  void _showDeliveryCompleteDialog(BuildContext context, Order order) {
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
