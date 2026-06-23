import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/driver_provider.dart';
import '../../utils/formatters.dart';

class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final MapController _mapController = MapController();
  dynamic order;
  bool _isLoading = true;

  // Default coordinates (Lilongwe, Malawi)
  static const LatLng _defaultLocation = LatLng(-13.9626, 33.7741);

  LatLng _pickupLocation = _defaultLocation;
  LatLng _deliveryLocation = LatLng(
    _defaultLocation.latitude + 0.01,
    _defaultLocation.longitude + 0.01,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOrderData();
  }

  // ✅ UPDATED: Cleaner _loadOrderData method
  void _loadOrderData() {
    final args = ModalRoute.of(context)?.settings.arguments;

    // Handle different argument types
    if (args is Map) {
      order = args['order'];
    } else if (args != null) {
      order = args;
    }

    // If order was passed as a String ID, fetch it from provider
    if (order is String) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      final results = driverProvider.assignedOrders
          .where((o) => o.id.toString() == order);
      if (results.isNotEmpty) {
        order = results.first;
        print('✅ Found order by ID: ${order.orderNumber}');
      } else {
        print('❌ Order not found with ID: $order');
      }
    }

    if (order != null) {
      _setupLocations();
      print('✅ Order loaded: ${order.orderNumber}');
    } else {
      print('❌ Order is null after loading');
    }

    _isLoading = false;
    setState(() {});
  }

  void _setupLocations() {
    try {
      if (order.sellerLatitude != null && order.sellerLongitude != null) {
        _pickupLocation = LatLng(
          double.parse(order.sellerLatitude.toString()),
          double.parse(order.sellerLongitude.toString()),
        );
      }
    } catch (e) {
      _pickupLocation = _defaultLocation;
    }

    try {
      if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
        _deliveryLocation = LatLng(
          double.parse(order.deliveryLatitude.toString()),
          double.parse(order.deliveryLongitude.toString()),
        );
      }
    } catch (e) {
      _deliveryLocation = LatLng(
        _defaultLocation.latitude + 0.01,
        _defaultLocation.longitude + 0.01,
      );
    }
  }

  LatLng get _mapCenter => LatLng(
        (_pickupLocation.latitude + _deliveryLocation.latitude) / 2,
        (_pickupLocation.longitude + _deliveryLocation.longitude) / 2,
      );

  Future<void> _openGoogleMaps(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final String url =
        'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final String url = 'tel:$phoneNumber';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Delivery Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            onPressed: () => _makePhoneCall(order?.customerPhone),
          ),
          IconButton(
            icon: const Icon(Icons.navigation, color: Colors.blue),
            onPressed: () => _openGoogleMaps(order?.deliveryAddress ?? ''),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Order not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please go back and try again',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A1A2B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Map
                    Expanded(
                      flex: 2,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.malawi_delivery',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [_pickupLocation, _deliveryLocation],
                                color: Colors.blue,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              // Pickup marker (blue)
                              Marker(
                                point: _pickupLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.storefront,
                                  color: Colors.blue,
                                  size: 36,
                                ),
                              ),
                              // Delivery marker (green)
                              Marker(
                                point: _deliveryLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Order details
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusHeader(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderNumber ??
                                        'Order #${order.id ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    Formatters.currencyFormat(
                                        order.total ?? order.amount ?? 0),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLocationRow(
                                icon: Icons.storefront,
                                iconColor: Colors.blue,
                                title: 'Pickup from',
                                subtitle: order.sellerName ?? 'Store',
                                address: order.sellerAddress ??
                                    order.pickupAddress ??
                                    'Pickup location',
                              ),
                              const SizedBox(height: 8),
                              _buildLocationRow(
                                icon: Icons.location_on,
                                iconColor: Colors.green,
                                title: 'Deliver to',
                                subtitle: order.customerName ?? 'Customer',
                                address: order.deliveryAddress ??
                                    'Delivery location',
                              ),
                              const SizedBox(height: 12),
                              if (order.items != null &&
                                  order.items.isNotEmpty) ...[
                                const Divider(),
                                const Text(
                                  'Order Items',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(
                                  order.items.length,
                                  (index) =>
                                      _buildOrderItem(order.items[index]),
                                ),
                              ],
                              const SizedBox(height: 8),
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Customer',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.customerName ?? 'Customer',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        if (order.customerPhone != null) ...[
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () => _makePhoneCall(
                                                order.customerPhone),
                                            child: Text(
                                              order.customerPhone,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.blue.shade700),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Seller',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.sellerName ?? 'Store',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        if (order.sellerPhone != null) ...[
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () => _makePhoneCall(
                                                order.sellerPhone),
                                            child: Text(
                                              order.sellerPhone,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.blue.shade700),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatusHeader() {
    final status = order.status?.toLowerCase() ?? 'pending';
    final isPickedUp = status == 'picked_up' || status == 'in_transit' || status == 'driving';
    final isDelivered = status == 'delivered' || status == 'completed';
    final isPending = status == 'pending' || status == 'accepted' || status == 'confirmed' || status == 'ready';

    String getHeaderText() {
      if (isDelivered) return 'Delivery Completed 🎉';
      if (isPickedUp) return 'Head to Customer';
      if (isPending) return 'Head to Pickup';
      return 'Order Details';
    }

    Color getStatusColor() {
      if (isDelivered) return Colors.green;
      if (isPickedUp) return Colors.blue;
      if (isPending) return Colors.orange;
      return Colors.grey;
    }

    String getStatusDisplay() {
      if (isDelivered) return 'DELIVERED';
      if (isPickedUp) return 'IN PROGRESS';
      if (isPending) return 'PENDING';
      return status.toUpperCase();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          getHeaderText(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            getStatusDisplay(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: getStatusColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              Text(subtitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(address,
                  style:
                      TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item['quantity'] ?? 0}x ${item['name'] ?? 'Item'}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            Formatters.currencyFormat(
                (item['price'] ?? 0) * (item['quantity'] ?? 0)),
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = order.status?.toLowerCase() ?? 'pending';
    final isPickedUp = status == 'picked_up' || status == 'in_transit' || status == 'driving';
    final isPending = status == 'pending' || status == 'accepted' || status == 'confirmed' || status == 'ready';
    final isDelivered = status == 'delivered' || status == 'completed';

    if (isDelivered) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Delivery Completed',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (isPickedUp)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showCompleteDialog,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        else if (isPending)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showPickupDialog,
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Pick Up Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1A2B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                _openGoogleMaps(order.deliveryAddress ?? ''),
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ FIXED: _showPickupDialog with ScaffoldMessenger saved before async
  void _showPickupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Pickup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ready to pick up this order from the seller?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📍 ${order.sellerName ?? 'Store'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close dialog
                Navigator.pop(dialogContext);
                
                // Get provider
                final driverProvider =
                    Provider.of<DriverProvider>(context, listen: false);
                
                // ✅ Save ScaffoldMessenger before async
                final messenger = ScaffoldMessenger.of(context);
                
                // Perform async operation
                final success = await driverProvider.updateDeliveryStatus(
                  order.id.toString(),
                  'pick_up'
                );
                
                // Use saved messenger for SnackBar
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Order picked up successfully' : '❌ ${driverProvider.error ?? 'Failed'}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                
                if (success && mounted) {
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1A2B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Pick Up'),
            ),
          ],
        );
      },
    );
  }

  // ✅ FIXED: _showCompleteDialog with ScaffoldMessenger saved before async
  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Complete Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confirm delivery to the customer?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📍 ${order.deliveryAddress ?? 'Delivery address'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close dialog
                Navigator.pop(dialogContext);
                
                // Get provider
                final driverProvider =
                    Provider.of<DriverProvider>(context, listen: false);
                
                // ✅ Save ScaffoldMessenger before async
                final messenger = ScaffoldMessenger.of(context);
                
                // Perform async operation
                final success = await driverProvider.updateDeliveryStatus(
                  order.id.toString(),
                  'deliver'
                );
                
                // Use saved messenger for SnackBar
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Delivery completed successfully 🎉' : '❌ ${driverProvider.error ?? 'Failed'}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                
                if (success && mounted) {
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}