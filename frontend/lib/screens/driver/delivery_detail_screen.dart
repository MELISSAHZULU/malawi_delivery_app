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
  dynamic _order;
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
      // Check if order was passed directly to widget
      if (widget.order != null) {
        _order = widget.order;
        print('✅ Order loaded from widget');
      } else {
        // Try to get from route arguments
        final args = ModalRoute.of(context)?.settings.arguments;
        print('📦 Route arguments: $args');
        
        if (args != null) {
          // Handle different argument types
          if (args is Map) {
            // Check if it has order_details (from assignment API)
            if (args.containsKey('order_details')) {
              _order = args['order_details'];
              print('✅ Extracted order_details from map');
            } else if (args.containsKey('order')) {
              _order = args['order'];
              print('✅ Extracted order from map');
            } else {
              // Try to use the map itself as order data
              _order = args;
              print('✅ Using args map as order data');
            }
          } else if (args is String) {
            // If it's a string ID, find the order
            final driverProvider = Provider.of<DriverProvider>(context, listen: false);
            final results = driverProvider.assignedOrders
                .where((o) => o.id.toString() == args || o.orderNumber == args);
            if (results.isNotEmpty) {
              _order = results.first;
              print('✅ Found order by ID: ${_order.orderNumber}');
            } else {
              print('❌ Order not found with ID: $args');
              _order = null;
            }
          } else {
            _order = args;
            print('✅ Using args directly');
          }
        }
      }
      
      // If order is a Map and has id but no order_number, try to find it
      if (_order is Map && _order.containsKey('id') && !_order.containsKey('order_number')) {
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        final orderId = _order['id'].toString();
        final results = driverProvider.assignedOrders
            .where((o) => o.id.toString() == orderId);
        if (results.isNotEmpty) {
          _order = results.first;
          print('✅ Found order by ID from map: ${_order.orderNumber}');
        }
      }
      
      if (_order != null) {
        _setupLocations();
        print('✅ Order loaded successfully');
        print('📦 Order data: $_order');
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
      // Handle both Map and Order object
      final isMap = _order is Map;
      
      if (isMap) {
        // Handle Map data
        final sellerLat = _order['seller_latitude'] ?? _order['sellerLatitude'];
        final sellerLng = _order['seller_longitude'] ?? _order['sellerLongitude'];
        final deliveryLat = _order['delivery_latitude'] ?? _order['deliveryLatitude'];
        final deliveryLng = _order['delivery_longitude'] ?? _order['deliveryLongitude'];
        
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
      } else {
        // Handle Order object
        if (_order.sellerLatitude != null && _order.sellerLongitude != null) {
          _pickupLocation = LatLng(
            _order.sellerLatitude,
            _order.sellerLongitude,
          );
        }
        
        if (_order.deliveryLatitude != null && _order.deliveryLongitude != null) {
          _deliveryLocation = LatLng(
            _order.deliveryLatitude,
            _order.deliveryLongitude,
          );
        }
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

  // Helper to get value from order (handles both Map and Object)
  dynamic _getOrderValue(String key, {dynamic defaultValue}) {
    if (_order == null) return defaultValue;
    if (_order is Map) {
      return _order[key] ?? defaultValue;
    }
    // Try to get property from object
    try {
      return _order[key] ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  String _getOrderNumber() {
    return _getOrderValue('order_number', defaultValue: 'N/A') ?? 'N/A';
  }

  String _getStatus() {
    return _getOrderValue('status', defaultValue: 'pending') ?? 'pending';
  }

  String _getSellerName() {
    return _getOrderValue('seller_name', defaultValue: 'Store') ?? 'Store';
  }

  String _getSellerAddress() {
    return _getOrderValue('seller_address', defaultValue: 'Pickup location') ?? 'Pickup location';
  }

  String _getDeliveryAddress() {
    return _getOrderValue('delivery_address', defaultValue: 'Delivery location') ?? 'Delivery location';
  }

  String _getCustomerName() {
    return _getOrderValue('customer_name', defaultValue: 'Customer') ?? 'Customer';
  }

  String _getCustomerPhone() {
    return _getOrderValue('customer_phone', defaultValue: '') ?? '';
  }

  String _getDriverName() {
    return _getOrderValue('driver_name', defaultValue: 'Driver') ?? 'Driver';
  }

  String _getDriverPhone() {
    return _getOrderValue('driver_phone', defaultValue: '') ?? '';
  }

  double _getTotal() {
    final total = _getOrderValue('total', defaultValue: 0.0);
    if (total is double) return total;
    if (total is int) return total.toDouble();
    if (total is String) return double.tryParse(total) ?? 0.0;
    return 0.0;
  }

  List<dynamic> _getItems() {
    return _getOrderValue('items', defaultValue: []) ?? [];
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
                                  Text(
                                    Formatters.currencyFormat(_getTotal()),
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
                                subtitle: _getSellerName(),
                                address: _getSellerAddress(),
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
                              if (_getItems().isNotEmpty) ...[
                                const Divider(),
                                const Text(
                                  'Order Items',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._getItems().map((item) => Padding(
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
                                          (item['price'] ?? 0) * (item['quantity'] ?? 0)
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                              const SizedBox(height: 8),
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
                    : '📍 ${_getSellerName()}',
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
                  orderId.toString(),
                  action
                );
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Action completed successfully' : '❌ ${driverProvider.error ?? 'Failed'}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                
                if (success && mounted) {
                  // Refresh the page
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
