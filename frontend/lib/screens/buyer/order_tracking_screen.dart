import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../providers/order_provider.dart';
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
  late WebSocketChannel _channel;
  Order? _order;
  String _orderStatus = 'pending';
  String _estimatedArrival = 'Calculating...';
  String _latestArrival = 'Calculating...';
  bool _showMap = true;

  final MapController _mapController = MapController();
  static const LatLng _defaultLocation = LatLng(-13.9626, 33.7741);
  
  LatLng _pickupLocation = _defaultLocation;
  LatLng _deliveryLocation = _defaultLocation;
  LatLng _driverLocationPoint = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel.sink.close();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      if (orderProvider.orders.isEmpty) {
        await orderProvider.fetchOrders();
      }
      
      Order? foundOrder;
      try {
        foundOrder = orderProvider.orders.firstWhere(
          (o) => o.id.toString() == widget.orderId || o.orderNumber == widget.orderId,
        );
      } catch (_) {
        await orderProvider.trackOrder(widget.orderId);
        foundOrder = orderProvider.currentOrder;
      }
      
      if (foundOrder != null) {
        // Now foundOrder is guaranteed to be non-null inside this block
        final order = foundOrder; // This is now Order (non-nullable)
        setState(() {
          _order = order;
          _orderStatus = order.status;
          _setupLocations(order);
          _updateETA(order);
        });
      } else {
        setState(() => _error = 'Order not found');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load order details');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupLocations(Order order) {
    try {
      if (order.sellerLatitude != null && order.sellerLongitude != null) {
        _pickupLocation = LatLng(order.sellerLatitude!, order.sellerLongitude!);
      }
    } catch (_) {}

    try {
      if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
        _deliveryLocation = LatLng(order.deliveryLatitude!, order.deliveryLongitude!);
      }
    } catch (_) {}

    _driverLocationPoint = _pickupLocation;
  }

  void _updateETA(Order order) {
    final now = DateTime.now();
    setState(() {
      _estimatedArrival = _formatTime(now.add(const Duration(minutes: 25)));
      _latestArrival = _formatTime(now.add(const Duration(minutes: 40)));
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    final hour12 = time.hour > 12 ? time.hour - 12 : time.hour;
    return '$hour12:$minute $ampm';
  }

  void _connectWebSocket() {
    try {
      final wsUrl = 'ws://localhost:8000/ws/delivery/${widget.orderId}/';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel.stream.listen(
        (data) {
          final event = jsonDecode(data);
          _handleWebSocketEvent(event);
        },
        onError: (error) => print('WebSocket error: $error'),
        onDone: () {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) _connectWebSocket();
          });
        },
      );
    } catch (e) {
      _startPolling();
    }
  }

  void _handleWebSocketEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;

    switch (type) {
      case 'driver_location':
        setState(() {
          _driverLocationPoint = LatLng(
            (event['latitude'] as num).toDouble(),
            (event['longitude'] as num).toDouble(),
          );
          _estimatedArrival = event['eta'] as String? ?? _estimatedArrival;
          _updateOrderDriverInfo(event);
        });
        break;

      case 'status_update':
        setState(() {
          _orderStatus = event['status'] as String? ?? _orderStatus;
          if (_order != null) {
            _order = _order!.copyWith(status: _orderStatus);
          }
        });
        break;

      case 'driver_assigned':
        setState(() {
          _updateOrderDriverInfo(event);
        });
        break;

      default:
        break;
    }
  }

  void _updateOrderDriverInfo(Map<String, dynamic> event) {
    if (_order == null) return;
    _order = _order!.copyWith(
      driverName: event['driver_name'] as String? ?? _order!.driverName,
      driverPhone: event['driver_phone'] as String? ?? _order!.driverPhone,
      driverVehicle: event['vehicle'] as String? ?? _order!.driverVehicle,
      driverRating: event['rating'] as double? ?? _order!.driverRating,
      assignmentId: event['assignment_id'] as String? ?? _order!.assignmentId,
    );
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadOrder();
        _startPolling();
      }
    });
  }

  LatLng get _mapCenter {
    if (_driverLocationPoint != _defaultLocation) return _driverLocationPoint;
    return LatLng(
      (_pickupLocation.latitude + _deliveryLocation.latitude) / 2,
      (_pickupLocation.longitude + _deliveryLocation.longitude) / 2,
    );
  }

  bool get _isDelivered => _orderStatus == 'delivered';
  bool get _isDriving => _orderStatus == 'driving' || _orderStatus == 'picked_up';
  bool get _isPreparing => _orderStatus == 'preparing' || _orderStatus == 'ready';
  bool get _isPending => _orderStatus == 'pending' || _orderStatus == 'confirmed';

  String get _statusDisplay {
    if (_order != null) return _order!.statusDisplay;
    switch (_orderStatus) {
      case 'pending':
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing Your Order';
      case 'ready':
        return 'Ready for Pickup';
      case 'picked_up':
        return 'Picked Up';
      case 'driving':
        return 'On The Way';
      case 'delivered':
        return 'Delivered 🎉';
      default:
        return _orderStatus.toUpperCase();
    }
  }

  Color get _statusColor {
    switch (_orderStatus) {
      case 'pending':
      case 'confirmed':
        return Colors.orange;
      case 'preparing':
      case 'ready':
        return Colors.purple;
      case 'picked_up':
        return Colors.teal;
      case 'driving':
        return const Color(0xFF2A7DE1);
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (_orderStatus) {
      case 'pending':
      case 'confirmed':
        return Icons.receipt_long;
      case 'preparing':
      case 'ready':
        return Icons.restaurant;
      case 'picked_up':
        return Icons.shopping_bag;
      case 'driving':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Track Order'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0A1A2B),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          if (_order?.driverPhone != null && _order!.driverPhone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: () => _makePhoneCall(_order!.driverPhone!),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _order == null
                  ? _buildEmptyState()
                  : _showMap
                      ? _buildMapView()
                      : _buildListView(),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        Expanded(flex: 45, child: _buildMap()),
        Expanded(flex: 20, child: _buildStatusAndDriverInfo()),
        Expanded(flex: 35, child: _buildDetailsAndTimeline()),
      ],
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusAndDriverInfo(),
          const SizedBox(height: 16),
          _buildTimeline(),
          const SizedBox(height: 16),
          _buildOrderSummary(),
          const SizedBox(height: 16),
          _buildDeliveryAddress(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _mapCenter, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.malawi_delivery',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [
                    if (_isDriving) _driverLocationPoint else _pickupLocation,
                    _deliveryLocation,
                  ],
                  color: const Color(0xFF2A7DE1),
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
                  child: const Icon(Icons.storefront, color: Color(0xFFF59E0B), size: 36),
                ),
                Marker(
                  point: _deliveryLocation,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Color(0xFF1F8B4C), size: 36),
                ),
                if (_isDriving)
                  Marker(
                    point: _driverLocationPoint,
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A7DE1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.delivery_dining, color: Colors.white, size: 16),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A7DE1).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('LIVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0A1A2B))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusAndDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated Arrival', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(_estimatedArrival, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A1A2B))),
                  Text('Latest arrival by $_latestArrival', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon, color: _statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(_statusDisplay, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_order?.driverName != null && _order!.driverName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF2A7DE1),
                    child: Text(_order!.driverName![0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_order!.driverName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(_order?.driverRating?.toStringAsFixed(1) ?? '4.8', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            if (_order?.driverVehicle != null && _order!.driverVehicle!.isNotEmpty)
                              Text(_order!.driverVehicle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_order?.driverPhone != null && _order!.driverPhone!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Color(0xFF2A7DE1)),
                      onPressed: () => _makePhoneCall(_order!.driverPhone!),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      {'label': 'Order Placed', 'icon': Icons.shopping_bag},
      {'label': 'Preparing', 'icon': Icons.restaurant},
      {'label': 'On The Way', 'icon': Icons.delivery_dining},
      {'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    int currentStep = 0;
    if (_isDelivered) currentStep = 3;
    else if (_isDriving) currentStep = 2;
    else if (_isPreparing) currentStep = 1;
    else if (_isPending) currentStep = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isComplete = index <= currentStep;
            final isActive = index == currentStep;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isComplete ? (isActive ? const Color(0xFF2A7DE1) : Colors.green) : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isComplete ? Icons.check : step['icon'] as IconData, size: 16, color: isComplete ? Colors.white : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step['label'] as String, style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isComplete ? const Color(0xFF0A1A2B) : Colors.grey.shade600,
                        )),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('In progress...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailsAndTimeline() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 16),
          _buildDeliveryAddress(),
          const SizedBox(height: 16),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${_order?.orderNumber ?? widget.orderId}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              Text(Formatters.currencyFormat(_order?.total ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A1A2B))),
            ],
          ),
          const SizedBox(height: 8),
          if (_order?.items.isNotEmpty ?? false)
            ..._order!.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 13)),
                  Text(Formatters.currencyFormat(item.price * item.quantity), style: const TextStyle(fontSize: 13)),
                ],
              ),
            )).toList(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(Formatters.currencyFormat(_order?.total ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A1A2B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF2A7DE1)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _order?.deliveryAddress ?? 'No address',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          if (_order?.deliveryInstructions != null && _order!.deliveryInstructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.note, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order!.deliveryInstructions!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
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
          Text(_error!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text('Please go back and try again', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1A2B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No Active Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('You don\'t have any active orders to track', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make call'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }
}
