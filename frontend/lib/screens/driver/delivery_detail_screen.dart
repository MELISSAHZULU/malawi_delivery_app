import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/driver_provider.dart';
import '../../utils/formatters.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final dynamic order;
  
  const DeliveryDetailScreen({Key? key, this.order}) : super(key: key);

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  // Default coordinates (Lilongwe, Malawi)
  static const LatLng _defaultLocation = LatLng(-13.9626, 33.7741);

  LatLng _pickupLocation = _defaultLocation;
  LatLng _deliveryLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOrderData();
  }

  void _loadOrderData() {
    setState(() => _isLoading = true);
    
    try {
      dynamic orderData = widget.order;
      
      // If widget.order is null, try to get from route arguments
      if (orderData == null) {
        final args = ModalRoute.of(context)?.settings.arguments;
        print('📦 Route arguments: $args');
        orderData = args;
      }
      
      if (orderData == null) {
        print('❌ No order data found');
        _order = null;
        return;
      }
      
      // Handle different data formats
      if (orderData is Map) {
        // Check if it has order_details (nested data from assignment)
        if (orderData.containsKey('order_details') && orderData['order_details'] is Map) {
          final details = orderData['order_details'] as Map;
          _order = Map<String, dynamic>.from(details);
          print('✅ Extracted order_details: ${_order?['order_number']}');
        } else {
          _order = Map<String, dynamic>.from(orderData);
          print('✅ Using order data directly: ${_order?['order_number']}');
        }
      } else if (orderData is String) {
        // If it's a string ID, try to find the order
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        final results = driverProvider.assignedOrders
            .where((o) => o.id.toString() == orderData || o.orderNumber == orderData);
        if (results.isNotEmpty) {
          final found = results.first;
          try {
            _order = Map<String, dynamic>.from(found.toJson());
            print('✅ Found order by ID: ${_order?['order_number']}');
          } catch (e) {
            print('❌ Could not convert found order to map: $e');
          }
        }
      } else {
        // Try to convert to map
        try {
          _order = Map<String, dynamic>.from(orderData.toJson());
          print('✅ Converted order to map: ${_order?['order_number']}');
        } catch (e) {
          print('❌ Could not convert order to map: $e');
          _order = null;
        }
      }
      
      // If we have an order but it's missing data, try to enrich it
      if (_order != null) {
        // Check if we need to extract from order_details (if it's still nested)
        if (_order!.containsKey('order_details') && _order!['order_details'] is Map) {
          final details = _order!['order_details'] as Map;
          _order = Map<String, dynamic>.from(details);
          print('✅ Extracted nested order_details: ${_order?['order_number']}');
        }
        
        _setupLocations();
        print('✅ Order loaded successfully: ${_order?['order_number']}');
        print('📦 Order data keys: ${_order?.keys}');
      } else {
        print('❌ Order is null after loading');
      }
    } catch (e) {
      print('❌ Error loading order: $e');
      _order = null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupLocations() {
    try {
      if (_order == null) return;
      
      // Get location data from map
      final sellerLat = _order?['seller_latitude'] ?? _order?['sellerLatitude'];
      final sellerLng = _order?['seller_longitude'] ?? _order?['sellerLongitude'];
      final deliveryLat = _order?['delivery_latitude'] ?? _order?['deliveryLatitude'];
      final deliveryLng = _order?['delivery_longitude'] ?? _order?['deliveryLongitude'];
      
      if (sellerLat != null && sellerLng != null) {
        _pickupLocation = LatLng(
          double.parse(sellerLat.toString()),
          double.parse(sellerLng.toString()),
        );
      }
      
      if (deliveryLat != null && deliveryLng != null) {
        _deliveryLocation = LatLng(
          double.parse(deliveryLat.toString()),
          double.parse(deliveryLng.toString()),
        );
      }
    } catch (e) {
      print('Error setting up locations: $e');
      _pickupLocation = _defaultLocation;
      _deliveryLocation = LatLng(
        _defaultLocation.latitude + 0.01,
        _defaultLocation.longitude + 0.01,
      );
    }
  }

  LatLng get _mapCenter {
    return LatLng(
      (_pickupLocation.latitude + _deliveryLocation.latitude) / 2,
      (_pickupLocation.longitude + _deliveryLocation.longitude) / 2,
    );
  }

  Future<void> _openGoogleMaps(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final String url = 'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress';
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

  // Helper to get value from order map - SAFE with null check
  dynamic _getOrderValue(String key, {dynamic defaultValue}) {
    // Return default if order is null
    if (_order == null) {
      print('⚠️ Order is null, returning default for key: $key');
      return defaultValue;
    }
    
    // Check multiple possible key names
    final possibleKeys = [key];
    
    // Handle common variations
    if (key == 'order_number') {
      possibleKeys.addAll(['orderNumber', 'order_no']);
    } else if (key == 'seller_name') {
      possibleKeys.addAll(['sellerName', 'store_name', 'storeName']);
    } else if (key == 'seller_address') {
      possibleKeys.addAll(['sellerAddress', 'store_address', 'storeAddress']);
    } else if (key == 'delivery_address') {
      possibleKeys.addAll(['deliveryAddress', 'address']);
    } else if (key == 'customer_name') {
      possibleKeys.addAll(['customerName', 'buyer_name', 'buyerName']);
    } else if (key == 'customer_phone') {
      possibleKeys.addAll(['customerPhone', 'buyer_phone', 'buyerPhone']);
    } else if (key == 'delivery_fee') {
      possibleKeys.addAll(['deliveryFee', 'fee', 'driver_fee', 'driverFee']);
    }
    
    for (final k in possibleKeys) {
      if (_order!.containsKey(k) && _order![k] != null) {
        return _order![k];
      }
    }
    
    return defaultValue;
  }

  String _getOrderNumber() {
    final value = _getOrderValue('order_number', defaultValue: 'N/A');
    return value?.toString() ?? 'N/A';
  }

  String _getStatus() {
    final value = _getOrderValue('status', defaultValue: 'pending');
    return value?.toString() ?? 'pending';
  }

  String _getSellerName() {
    final value = _getOrderValue('seller_name', defaultValue: 'Store');
    return value?.toString() ?? 'Store';
  }

  String _getSellerAddress() {
    final value = _getOrderValue('seller_address', defaultValue: '');
    return value?.toString() ?? '';
  }

  String _getDeliveryAddress() {
    final value = _getOrderValue('delivery_address', defaultValue: 'Delivery location');
    return value?.toString() ?? 'Delivery location';
  }

  String _getCustomerName() {
    final value = _getOrderValue('customer_name', defaultValue: 'Customer');
    return value?.toString() ?? 'Customer';
  }

  String _getCustomerPhone() {
    final value = _getOrderValue('customer_phone', defaultValue: '');
    return value?.toString() ?? '';
  }

  String _getDriverName() {
    final value = _getOrderValue('driver_name', defaultValue: 'Driver');
    return value?.toString() ?? 'Driver';
  }

  String _getDriverPhone() {
    final value = _getOrderValue('driver_phone', defaultValue: '');
    return value?.toString() ?? '';
  }

  double _getDeliveryFee() {
    final value = _getOrderValue('delivery_fee', defaultValue: 1500.0);
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 1500.0;
    return 1500.0;
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
            onPressed: () => _makePhoneCall(_getCustomerPhone()),
          ),
          IconButton(
            icon: const Icon(Icons.navigation, color: Colors.blue),
            onPressed: () => _openGoogleMaps(_getDeliveryAddress()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? _buildErrorState()
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
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${_getOrderNumber()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  // Show only delivery fee, not full amount
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.motorcycle, size: 14, color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Fee: ${Formatters.currencyFormat(_getDeliveryFee())}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLocationRow(
                                icon: Icons.storefront,
                                iconColor: Colors.blue,
                                title: 'Pickup from',
                                subtitle: _getSellerName(),
                                address: _getSellerAddress().isNotEmpty ? _getSellerAddress() : 'Pickup location',
                              ),
                              const SizedBox(height: 8),
                              _buildLocationRow(
                                icon: Icons.location_on,
                                iconColor: Colors.green,
                                title: 'Deliver to',
                                subtitle: _getCustomerName(),
                                address: _getDeliveryAddress(),
                              ),
                              const SizedBox(height: 12),
                              
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Customer',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getCustomerName(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        if (_getCustomerPhone().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () => _makePhoneCall(_getCustomerPhone()),
                                            child: Text(
                                              _getCustomerPhone(),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue.shade700),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Seller',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getSellerName(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
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

  Widget _buildErrorState() {
    return Center(
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
    );
  }

  Widget _buildStatusHeader() {
    final status = _getStatus();
    final isDelivered = status == 'delivered' || status == 'completed';
    final isDriving = status == 'driving' || status == 'picked_up';
    final isPending = status == 'pending' || status == 'accepted' || status == 'confirmed' || status == 'ready';

    String getHeaderText() {
      if (isDelivered) return 'Delivery Completed 🎉';
      if (isDriving) return 'Head to Customer';
      if (isPending) return 'Head to Pickup';
      return 'Order Details';
    }

    Color getStatusColor() {
      if (isDelivered) return Colors.green;
      if (isDriving) return Colors.blue;
      if (isPending) return Colors.orange;
      return Colors.grey;
    }

    String getStatusDisplay() {
      if (isDelivered) return 'DELIVERED';
      if (isDriving) return 'IN PROGRESS';
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              Text(subtitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(address,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = _getStatus();
    final isDelivered = status == 'delivered' || status == 'completed';
    final isDriving = status == 'driving' || status == 'picked_up';
    final isPending = status == 'pending' || status == 'accepted' || status == 'confirmed' || status == 'ready';

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
        if (isDriving || isPending)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showActionDialog(),
              icon: const Icon(Icons.check_circle),
              label: Text(isDriving ? 'Complete Delivery' : 'Pick Up Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDriving ? Colors.green : const Color(0xFF0A1A2B),
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
            onPressed: () => _openGoogleMaps(_getDeliveryAddress()),
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

  void _showActionDialog() {
    final status = _getStatus();
    final isDriving = status == 'driving' || status == 'picked_up';
    final orderId = _getOrderValue('id');
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isDriving ? 'Complete Delivery' : 'Confirm Pickup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isDriving 
                ? 'Confirm delivery to the customer?' 
                : 'Ready to pick up this order from the seller?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDriving 
                    ? '📍 ${_getDeliveryAddress()}'
                    : '📍 ${_getSellerName()}\n${_getSellerAddress()}',
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
                Navigator.pop(dialogContext);
                
                final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                final action = isDriving ? 'deliver' : 'pick_up';
                
                final messenger = ScaffoldMessenger.of(context);
                final success = await driverProvider.updateDeliveryStatus(
                  orderId?.toString() ?? '',
                  action
                );
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Action completed successfully' : '❌ ${driverProvider.error ?? 'Failed'}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                
                if (success && mounted) {
                  _loadOrderData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDriving ? Colors.green : const Color(0xFF0A1A2B),
                foregroundColor: Colors.white,
              ),
              child: Text(isDriving ? 'Complete' : 'Pick Up'),
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
