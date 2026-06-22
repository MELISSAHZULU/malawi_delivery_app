import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../utils/formatters.dart';

class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  GoogleMapController? _mapController;
  dynamic order;
  bool _isLoading = true;
  
  // Default coordinates (Lilongwe, Malawi)
  static const LatLng _defaultLocation = LatLng(-13.9626, 33.7741);
  
  // Mock coordinates for demo - replace with actual from order
  LatLng _pickupLocation = _defaultLocation;
  LatLng _deliveryLocation = _defaultLocation;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOrderData();
  }

  void _loadOrderData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      order = args['order'];
      if (order != null) {
        _setupLocations();
      }
    }
    _isLoading = false;
    setState(() {});
  }

  void _setupLocations() {
    // Try to get actual coordinates from order
    try {
      if (order.sellerLatitude != null && order.sellerLongitude != null) {
        _pickupLocation = LatLng(
          double.parse(order.sellerLatitude.toString()),
          double.parse(order.sellerLongitude.toString()),
        );
      }
    } catch (e) {
      // Use default location
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
      // Use nearby location for demo
      _deliveryLocation = LatLng(
        _defaultLocation.latitude + 0.01,
        _defaultLocation.longitude + 0.01,
      );
    }

    // Add markers
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        infoWindow: const InfoWindow(title: 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLocation,
        infoWindow: const InfoWindow(title: 'Delivery Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    // Add route polyline
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_pickupLocation, _deliveryLocation],
        color: Colors.blue,
        width: 4,
        patterns: [
          PatternItem.dash(30),
          PatternItem.gap(10),
        ],
      ),
    };
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
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Call customer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📞 Calling customer...'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: () {
              // Open Google Maps
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗺️ Opening navigation...'),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(child: Text('Order not found'))
              : Column(
                  children: [
                    // Map
                    Expanded(
                      flex: 2,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _pickupLocation,
                          zoom: 14,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          // Fit camera to show both markers
                          _fitCameraToMarkers();
                        },
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
                              // Status Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Head to Pickup',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      order.status?.toUpperCase() ?? 'PENDING',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Order Number and Amount
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderNumber ?? 'Order #${order.id ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    Formatters.currencyFormat(order.total ?? order.amount ?? 0),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Pickup location
                              _buildLocationRow(
                                icon: Icons.storefront,
                                iconColor: Colors.blue,
                                title: 'Pickup from',
                                subtitle: order.sellerName ?? 'Store',
                                address: order.sellerAddress ?? order.pickupAddress ?? 'Pickup location',
                              ),
                              const SizedBox(height: 8),
                              
                              // Delivery location
                              _buildLocationRow(
                                icon: Icons.location_on,
                                iconColor: Colors.green,
                                title: 'Deliver to',
                                subtitle: order.customerName ?? 'Customer',
                                address: order.deliveryAddress ?? 'Delivery location',
                              ),
                              const SizedBox(height: 12),
                              
                              // Order Items
                              if (order.items != null && order.items.isNotEmpty) ...[
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
                                  (index) => _buildOrderItem(
                                    order.items[index],
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 8),
                              
                              // Customer and Seller info
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Customer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.customerName ?? 'Customer',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Seller',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.sellerName ?? 'Store',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
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
                      ),
                    ),
                  ],
                ),
      ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              (item['price'] ?? 0) * (item['quantity'] ?? 0)
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _fitCameraToMarkers() {
    if (_mapController == null) return;
    
    // Create bounds from both markers
    final bounds = LatLngBounds(
      southwest: LatLng(
        _pickupLocation.latitude < _deliveryLocation.latitude 
            ? _pickupLocation.latitude 
            : _deliveryLocation.latitude,
        _pickupLocation.longitude < _deliveryLocation.longitude 
            ? _pickupLocation.longitude 
            : _deliveryLocation.longitude,
      ),
      northeast: LatLng(
        _pickupLocation.latitude > _deliveryLocation.latitude 
            ? _pickupLocation.latitude 
            : _deliveryLocation.latitude,
        _pickupLocation.longitude > _deliveryLocation.longitude 
            ? _pickupLocation.longitude 
            : _deliveryLocation.longitude,
      ),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}