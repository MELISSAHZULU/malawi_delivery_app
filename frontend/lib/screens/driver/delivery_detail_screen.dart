import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/driver_provider.dart';
import '../../utils/formatters.dart';
import '../../models/order.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final dynamic order;
  
  const DeliveryDetailScreen({Key? key, this.order}) : super(key: key);

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final MapController _mapController = MapController();
  Order? _order;
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
      
      print('📦 Order data type: ${orderData.runtimeType}');
      
      // If it's already an Order object
      if (orderData is Order) {
        _order = orderData;
        print('✅ Using Order object directly: ${_order?.orderNumber}');
      } 
      // If it's a Map
      else if (orderData is Map) {
        // Convert to Order using fromJson
        try {
          // Handle different map structures
          Map<String, dynamic> dataMap = {};
          orderData.forEach((key, value) {
            dataMap[key.toString()] = value;
          });
          
          print('📦 Data map keys: ${dataMap.keys}');
          
          // Check if it has order_details (nested data from assignment)
          if (dataMap.containsKey('order_details') && dataMap['order_details'] is Map) {
            final details = dataMap['order_details'] as Map;
            Map<String, dynamic> detailsMap = {};
            details.forEach((key, value) {
              detailsMap[key.toString()] = value;
            });
            
            // Add assignment data
            detailsMap['assignment_id'] = dataMap['id']?.toString();
            detailsMap['driver_name'] = dataMap['driver_name'];
            detailsMap['driver_phone'] = dataMap['driver_phone'];
            detailsMap['seller_name'] = dataMap['seller_name'] ?? detailsMap['seller_name'];
            detailsMap['delivery_address'] = dataMap['delivery_address'] ?? detailsMap['delivery_address'];
            detailsMap['customer_name'] = dataMap['customer_name'] ?? detailsMap['customer_name'] ?? detailsMap['buyer_name'];
            detailsMap['customer_phone'] = dataMap['customer_phone'] ?? detailsMap['customer_phone'] ?? detailsMap['buyer_phone'];
            detailsMap['seller_latitude'] = dataMap['seller_latitude'] ?? detailsMap['seller_latitude'];
            detailsMap['seller_longitude'] = dataMap['seller_longitude'] ?? detailsMap['seller_longitude'];
            detailsMap['delivery_latitude'] = dataMap['delivery_latitude'] ?? detailsMap['delivery_latitude'];
            detailsMap['delivery_longitude'] = dataMap['delivery_longitude'] ?? detailsMap['delivery_longitude'];
            
            // Use assignment status
            if (dataMap.containsKey('status')) {
              detailsMap['status'] = dataMap['status'].toString();
              print('✅ Using assignment status: ${dataMap['status']}');
            }
            
            _order = Order.fromJson(detailsMap);
            print('✅ Extracted order_details: ${_order?.orderNumber}');
          } else {
            // Direct order data
            _order = Order.fromJson(dataMap);
            print('✅ Using order data directly: ${_order?.orderNumber}');
          }
          
          // Print debug info
          if (_order != null) {
            print('🔑 Order Number: ${_order?.orderNumber}');
            print('👤 Customer Name: ${_order?.customerName}');
            print('🏪 Seller Name: ${_order?.sellerName}');
            print('📍 Delivery Address: ${_order?.deliveryAddress}');
            print('📦 Status: ${_order?.status}');
            print('🆔 ID: ${_order?.id}');
          }
          
        } catch (e) {
          print('❌ Error parsing order from map: $e');
          _order = null;
        }
      } 
      // If it's a String ID
      else if (orderData is String) {
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        final found = driverProvider.getOrderById(orderData);
        if (found != null) {
          _order = found;
          print('✅ Found order by ID: ${_order?.orderNumber}');
        } else {
          print('❌ Order not found with ID: $orderData');
          _order = null;
        }
      } else {
        print('❌ Unexpected data type: ${orderData.runtimeType}');
        _order = null;
      }
      
      if (_order != null) {
        _setupLocations();
        print('✅ Order loaded successfully');
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
      
      // Get location data from order
      if (_order!.sellerLatitude != null && _order!.sellerLongitude != null) {
        _pickupLocation = LatLng(
          _order!.sellerLatitude!,
          _order!.sellerLongitude!,
        );
        print('📍 Pickup location set: ${_order!.sellerLatitude}, ${_order!.sellerLongitude}');
      }
      
      if (_order!.deliveryLatitude != null && _order!.deliveryLongitude != null) {
        _deliveryLocation = LatLng(
          _order!.deliveryLatitude!,
          _order!.deliveryLongitude!,
        );
        print('📍 Delivery location set: ${_order!.deliveryLatitude}, ${_order!.deliveryLongitude}');
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
            onPressed: () => _makePhoneCall(_order?.customerPhone),
          ),
          IconButton(
            icon: const Icon(Icons.navigation, color: Colors.blue),
            onPressed: () => _openGoogleMaps(_order?.deliveryAddress ?? ''),
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
                              // Pickup marker (blue - store)
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
                              // Delivery marker (green - customer)
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
                                    'Order #${_order?.orderNumber ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
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
                                          'Fee: ${Formatters.currencyFormat(_order?.deliveryFee ?? 0)}',
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
                              
                              // Seller info with name and address
                              _buildLocationRow(
                                icon: Icons.storefront,
                                iconColor: Colors.blue,
                                title: 'Pickup from',
                                subtitle: _order?.sellerName ?? 'Store',
                                address: _order?.sellerAddress ?? 'Pickup location',
                              ),
                              const SizedBox(height: 8),
                              
                              // Customer info with name and address
                              _buildLocationRow(
                                icon: Icons.location_on,
                                iconColor: Colors.green,
                                title: 'Deliver to',
                                subtitle: _order?.customerName ?? 'Customer',
                                address: _order?.deliveryAddress ?? 'Delivery location',
                              ),
                              const SizedBox(height: 12),
                              
                              const Divider(),
                              
                              // Customer details section
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Customer Details',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A1A2B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          _order?.customerName ?? 'Customer',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_order?.customerPhone != null && _order!.customerPhone!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => _makePhoneCall(_order?.customerPhone),
                                            child: Text(
                                              _order!.customerPhone!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              const Divider(),
                              
                              // Seller details section
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Seller Details',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A1A2B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.store, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          _order?.sellerName ?? 'Store',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_order?.sellerAddress != null && _order!.sellerAddress!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _order!.sellerAddress!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              const Divider(),
                              
                              // ✅ Only Navigate button
                              _buildNavigateButton(),
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
    final status = _order?.effectiveStatus ?? 'pending';
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
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              if (address.isNotEmpty)
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigateButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openGoogleMaps(_order?.deliveryAddress ?? ''),
        icon: const Icon(Icons.navigation),
        label: const Text('Navigate to Delivery Location'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(color: Colors.blue),
        ),
      ),
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
