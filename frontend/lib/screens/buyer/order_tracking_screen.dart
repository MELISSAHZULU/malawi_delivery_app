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
import '../../routes/app_routes.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _isLoading = true;
  String? _error;
  WebSocketChannel? _channel;
  Order? _order;
  String _orderStatus = 'pending';
  String _estimatedArrival = 'Calculating...';
  String _latestArrival = 'Calculating...';
  bool _showMap = false;
  bool _isWebSocketConnected = false;

  final MapController _mapController = MapController();
  static const LatLng _defaultLocation = LatLng(-13.9626, 33.7741);
  
  LatLng _pickupLocation = _defaultLocation;
  LatLng _deliveryLocation = _defaultLocation;
  LatLng _driverLocationPoint = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If we have an order and no WebSocket connection, try to connect
    if (_order != null && _order!.id.isNotEmpty && _order!.id != '0') {
      _connectWebSocket(_order!.id);
    }
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      if (orderProvider.orders.isEmpty) {
        await orderProvider.fetchOrders();
      }
      
      Order? foundOrder;
      
      if (widget.orderId.isEmpty || widget.orderId == '0') {
        if (orderProvider.orders.isNotEmpty) {
          foundOrder = orderProvider.orders.first;
        }
      } else {
        try {
          foundOrder = orderProvider.orders.firstWhere(
            (o) => o.id.toString() == widget.orderId || o.orderNumber == widget.orderId,
          );
        } catch (_) {
          await orderProvider.trackOrder(widget.orderId);
          foundOrder = orderProvider.currentOrder;
        }
      }
      
      if (foundOrder != null) {
        final order = foundOrder;
        setState(() {
          _order = order;
          _orderStatus = order.status;
          _setupLocations(order);
          _updateETA(order);
        });
        if (order.id.isNotEmpty && order.id != '0') {
          _connectWebSocket(order.id);
        }
      } else {
        setState(() => _error = 'No orders found');
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

  void _connectWebSocket(String orderId) {
    if (orderId.isEmpty || orderId == '0') {
      return;
    }

    try {
      final wsUrl = 'ws://localhost:8000/ws/delivery/$orderId/';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isWebSocketConnected = true;
      
      _channel!.stream.listen(
        (data) {
          try {
            final event = jsonDecode(data);
            _handleWebSocketEvent(event);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isWebSocketConnected = false;
        },
        onDone: () {
          _isWebSocketConnected = false;
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _order != null && _order!.id.isNotEmpty) {
              _connectWebSocket(_order!.id);
            }
          });
        },
      );
    } catch (e) {
      _isWebSocketConnected = false;
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
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to home screen when back button is pressed
        Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
        return false; // We already handled navigation
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate to home screen when back button is pressed
              Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
            },
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
      ),
    );
  }

  // ==================== MAP VIEW ====================
  Widget _buildMapView() {
    return Column(
      children: [
        Expanded(
          flex: 50,
          child: _buildMap(),
        ),
        Expanded(
          flex: 50,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildStatusAndDriverInfo(),
                const SizedBox(height: 12),
                _buildTimeline(),
                const SizedBox(height: 12),
                _buildOrderSummary(),
                const SizedBox(height: 12),
                _buildDeliveryAddress(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== LIST VIEW ====================
  Widget _buildListView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusAndDriverInfo(),
          const SizedBox(height: 16),
          _buildTimeline(),
          const SizedBox(height: 16),
          _buildOrderSummary(),
          const SizedBox(height: 16),
          _buildDeliveryAddress(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================== MAP ====================
  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: 14,
          ),
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
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isWebSocketConnected ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isWebSocketConnected ? 'LIVE' : 'POLLING',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: _isWebSocketConnected ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== STATUS & DRIVER INFO ====================
  Widget _buildStatusAndDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8)],
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
                  const Text('Estimated Arrival', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(_estimatedArrival, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1A2B))),
                  Text('Latest by $_latestArrival', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon, color: _statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(_statusDisplay, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_order?.driverName != null && _order!.driverName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2A7DE1),
                    child: Text(_order!.driverName![0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_order!.driverName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text(_order?.driverRating?.toStringAsFixed(1) ?? '4.8', style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 6),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            if (_order?.driverVehicle != null && _order!.driverVehicle!.isNotEmpty)
                              Text(_order!.driverVehicle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_order?.driverPhone != null && _order!.driverPhone!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Color(0xFF2A7DE1), size: 20),
                      onPressed: () => _makePhoneCall(_order!.driverPhone!),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== TIMELINE ====================
  Widget _buildTimeline() {
    final steps = [
      {'label': 'Placed', 'icon': Icons.shopping_bag},
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isComplete = index < currentStep;
            final isActive = index == currentStep;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isComplete ? Colors.green : (isActive ? const Color(0xFF2A7DE1) : Colors.grey.shade200),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isComplete ? Icons.check : step['icon'] as IconData,
                      size: 12,
                      color: (isComplete || isActive) ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                        color: (isComplete || isActive) ? const Color(0xFF0A1A2B) : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (isActive && !_isDelivered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2A7DE1)),
                      ),
                    ),
                  if (isComplete && index == steps.length - 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Done!',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
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

  // ==================== ORDER SUMMARY ====================
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${_order?.orderNumber ?? widget.orderId}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Text(Formatters.currencyFormat(_order?.total ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0A1A2B))),
            ],
          ),
          const SizedBox(height: 6),
          if (_order?.items.isNotEmpty ?? false)
            ..._order!.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 12)),
                  Text(Formatters.currencyFormat(item.price * item.quantity), style: const TextStyle(fontSize: 12)),
                ],
              ),
            )).toList(),
          const Divider(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(Formatters.currencyFormat(_order?.total ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0A1A2B))),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DELIVERY ADDRESS ====================
  Widget _buildDeliveryAddress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF2A7DE1)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _order?.deliveryAddress ?? 'No address',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          if (_order?.deliveryInstructions != null && _order!.deliveryInstructions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.note, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _order!.deliveryInstructions!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
    if (_error == 'No orders found') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No Orders Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1A2B))),
            const SizedBox(height: 4),
            Text('Place your first order to track it', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.buyerHome),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Go Back Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1A2B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text('Please go back and try again', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.buyerHome),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Go Back Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1A2B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No Active Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1A2B))),
          const SizedBox(height: 4),
          Text('You don\'t have any active orders', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.buyerHome),
            child: const Text('Go Back Home'),
          ),
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
