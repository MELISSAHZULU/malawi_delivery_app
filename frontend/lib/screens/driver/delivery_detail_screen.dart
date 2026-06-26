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
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String _orderId = '';

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
        _orderData = null;
        return;
      }
      
      print('📦 Order data type: ${orderData.runtimeType}');
      
      if (orderData is Map) {
        Map<String, dynamic> dataMap = {};
        orderData.forEach((key, value) {
          dataMap[key.toString()] = value;
        });
        
        print('📦 Data map keys: ${dataMap.keys}');
        
        if (dataMap.containsKey('order') && dataMap['order'] is Map) {
          final wrapped = dataMap['order'] as Map;
          Map<String, dynamic> wrappedMap = {};
          wrapped.forEach((key, value) {
            wrappedMap[key.toString()] = value;
          });
          _orderData = wrappedMap;
          _orderId = wrappedMap['id']?.toString() ?? '';
          print('✅ Extracted wrapped order data');
        } 
        else if (dataMap.containsKey('order_details') && dataMap['order_details'] is Map) {
          final details = dataMap['order_details'] as Map;
          Map<String, dynamic> detailsMap = {};
          details.forEach((key, value) {
            detailsMap[key.toString()] = value;
          });
          
          detailsMap['assignment_id'] = dataMap['id']?.toString();
          detailsMap['driver_name'] = dataMap['driver_name'];
          detailsMap['driver_phone'] = dataMap['driver_phone'];
          detailsMap['seller_name'] = dataMap['seller_name'] ?? detailsMap['seller_name'];
          detailsMap['delivery_address'] = dataMap['delivery_address'] ?? detailsMap['delivery_address'];
          detailsMap['customer_name'] = dataMap['customer_name'] ?? detailsMap['customer_name'] ?? detailsMap['buyer_name'];
          detailsMap['customer_phone'] = dataMap['customer_phone'] ?? detailsMap['customer_phone'] ?? detailsMap['buyer_phone'];
          
          if (dataMap.containsKey('status')) {
            detailsMap['status'] = dataMap['status'].toString();
            print('✅ Using assignment status: ${dataMap['status']}');
          }
          
          _orderData = detailsMap;
          _orderId = dataMap['id']?.toString() ?? '';
          print('✅ Extracted order_details');
        } else {
          _orderData = dataMap;
          _orderId = dataMap['id']?.toString() ?? '';
          print('✅ Using order data directly');
        }
        
        if (_orderData != null) {
          print('🔑 ALL KEYS: ${_orderData!.keys.toList()}');
          print('🆔 id value: ${_orderData!['id']}');
          print('👤 customer_name: ${_orderData!['customer_name']}');
          print('🏪 seller_name: ${_orderData!['seller_name']}');
          print('📍 delivery_address: ${_orderData!['delivery_address']}');
        }
        
        if (_orderId.isEmpty || _orderId == 'null' || _orderId == '0') {
          if (_orderData!.containsKey('assignment_id')) {
            _orderId = _orderData!['assignment_id'].toString();
          } else if (_orderData!.containsKey('order_id')) {
            _orderId = _orderData!['order_id'].toString();
          } else if (_orderData!.containsKey('id')) {
            _orderId = _orderData!['id'].toString();
          }
        }
        
        print('✅ Final Order ID: $_orderId');
        
      } else if (orderData is String) {
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        final found = driverProvider.getOrderById(orderData);
        if (found != null) {
          _orderData = found.toJson();
          _orderId = orderData;
          print('✅ Found order by ID: ${_orderData?['order_number']}');
        } else {
          print('❌ Order not found with ID: $orderData');
          _orderData = null;
        }
      } else {
        try {
          final map = orderData.toJson() as Map;
          Map<String, dynamic> dataMap = {};
          map.forEach((key, value) {
            dataMap[key.toString()] = value;
          });
          _orderData = dataMap;
          _orderId = dataMap['id']?.toString() ?? '';
          print('✅ Converted order to map: ${_orderData?['order_number']}');
        } catch (e) {
          print('❌ Could not convert order: $e');
          _orderData = null;
        }
      }
      
      if (_orderData != null) {
        _setupLocations();
        print('✅ Order loaded successfully');
      } else {
        print('❌ Order is null after loading');
      }
    } catch (e) {
      print('❌ Error loading order: $e');
      _orderData = null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupLocations() {
    try {
      if (_orderData == null) return;
      
      final sellerLat = _orderData?['seller_latitude'] ?? _orderData?['sellerLatitude'];
      final sellerLng = _orderData?['seller_longitude'] ?? _orderData?['sellerLongitude'];
      final deliveryLat = _orderData?['delivery_latitude'] ?? _orderData?['deliveryLatitude'];
      final deliveryLng = _orderData?['delivery_longitude'] ?? _orderData?['deliveryLongitude'];
      
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

  String _getValue(String key, {String defaultValue = ''}) {
    if (_orderData == null) return defaultValue;
    
    if (_orderData!.containsKey(key) && _orderData![key] != null) {
      return _orderData![key].toString();
    }
    
    final camelKey = _toCamelCase(key);
    if (_orderData!.containsKey(camelKey) && _orderData![camelKey] != null) {
      return _orderData![camelKey].toString();
    }
    
    return defaultValue;
  }

  String _toCamelCase(String snake) {
    final parts = snake.split('_');
    if (parts.length <= 1) return snake;
    return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join('');
  }

  String _getOrderNumber() {
    return _getValue('order_number', defaultValue: 'N/A');
  }

  String _getStatus() {
    final assignmentStatus = _getValue('status');
    if (assignmentStatus.isNotEmpty && assignmentStatus != 'pending') {
      return assignmentStatus;
    }
    return _getValue('order_status', defaultValue: 'pending');
  }

  String _getSellerName() {
    return _getValue('seller_name', defaultValue: 'Store');
  }

  String _getSellerAddress() {
    return _getValue('seller_address', defaultValue: '');
  }

  String _getDeliveryAddress() {
    return _getValue('delivery_address', defaultValue: 'Delivery location');
  }

  String _getCustomerName() {
    final name = _getValue('customer_name');
    if (name.isNotEmpty) return name;
    return _getValue('buyer_name', defaultValue: 'Customer');
  }

  String _getCustomerPhone() {
    final phone = _getValue('customer_phone');
    if (phone.isNotEmpty) return phone;
    return _getValue('buyer_phone', defaultValue: '');
  }

  double _getDeliveryFee() {
    if (_orderData == null) return 1500.0;
    
    if (_orderData!.containsKey('delivery_fee')) {
      final value = _orderData!['delivery_fee'];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 1500.0;
    }
    
    if (_orderData!.containsKey('deliveryFee')) {
      final value = _orderData!['deliveryFee'];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 1500.0;
    }
    
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
          : _orderData == null
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
                              
                              // ✅ Only Navigate button - no action buttons
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

  // ✅ Only Navigate button - no action buttons
  Widget _buildNavigateButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openGoogleMaps(_getDeliveryAddress()),
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
