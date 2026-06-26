// lib/models/order.dart

import 'cart_item.dart';

class Order {
  final String id;
  final String? assignmentId; // driver assignment id
  final String orderNumber;
  final String status;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle; // vehicle type
  final double? driverRating; // driver rating
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerAddress;
  final String? pickupAddress;
  final String? buyerName;
  final String? customerName;
  final String? customerPhone;
  final double? sellerLatitude;
  final double? sellerLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryInstructions; // delivery notes

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.driverRating,
    this.assignmentId,
    required this.createdAt,
    this.estimatedDeliveryTime,
    this.paymentStatus,
    this.paymentMethod,
    this.sellerName,
    this.sellerPhone,
    this.sellerAddress,
    this.pickupAddress,
    this.buyerName,
    this.customerName,
    this.customerPhone,
    this.sellerLatitude,
    this.sellerLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryInstructions,
  });

  // ==================== copyWith Method ====================
  Order copyWith({
    String? id,
    String? assignmentId,
    String? orderNumber,
    String? status,
    List<CartItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    String? deliveryAddress,
    String? driverName,
    String? driverPhone,
    String? driverVehicle,
    double? driverRating,
    DateTime? createdAt,
    DateTime? estimatedDeliveryTime,
    String? paymentStatus,
    String? paymentMethod,
    String? sellerName,
    String? sellerPhone,
    String? sellerAddress,
    String? pickupAddress,
    String? buyerName,
    String? customerName,
    String? customerPhone,
    double? sellerLatitude,
    double? sellerLongitude,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryInstructions,
  }) {
    return Order(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverVehicle: driverVehicle ?? this.driverVehicle,
      driverRating: driverRating ?? this.driverRating,
      createdAt: createdAt ?? this.createdAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      buyerName: buyerName ?? this.buyerName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      sellerLatitude: sellerLatitude ?? this.sellerLatitude,
      sellerLongitude: sellerLongitude ?? this.sellerLongitude,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
    );
  }

  // ==================== fromJson / toJson ====================
  factory Order.fromJson(Map<String, dynamic> json) {
    List<CartItem> parseItems(dynamic itemsData) {
      if (itemsData == null) return [];
      if (itemsData is List) {
        return itemsData.map((item) => CartItem.fromJson(item)).toList();
      }
      return [];
    }

    double parseTotal(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    String? parseDriverVehicle(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) return value;
      if (value is Map) {
        return value['vehicle_type'] ?? value['vehicle'] ?? value['vehicleType'];
      }
      return null;
    }

    return Order(
      id: (json['id'] ?? '').toString(),
      orderNumber: json['order_number'] ?? json['orderNumber'] ?? '',
      status: json['status'] ?? 'pending',
      items: parseItems(json['items']),
      subtotal: parseTotal(json['subtotal']),
      deliveryFee: parseTotal(json['delivery_fee'] ?? json['deliveryFee']),
      total: parseTotal(json['total']),
      deliveryAddress: json['delivery_address'] ?? json['deliveryAddress'] ?? '',
      driverName: json['driver_name'] ?? json['driverName'] ?? json['driver_username'],
      driverPhone: json['driver_phone'] ?? json['driverPhone'] ?? json['driver_phone_number'],
      driverVehicle: parseDriverVehicle(json['driver_vehicle'] ?? json['driverVehicle'] ?? json['vehicle_type']),
      driverRating: parseNullableDouble(json['driver_rating'] ?? json['driverRating']),
      assignmentId: json['assignment_id'] ?? json['assignmentId'],
      createdAt: DateTime.parse(
          json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'])
          : json['estimatedDeliveryTime'] != null
              ? DateTime.parse(json['estimatedDeliveryTime'])
              : null,
      paymentStatus: json['payment_status'] ?? json['paymentStatus'],
      paymentMethod: json['payment_method'] ?? json['paymentMethod'],
      sellerName: json['seller_name'] ?? json['sellerName'] ?? json['store_name'],
      sellerPhone: json['seller_phone'] ?? json['sellerPhone'] ?? json['store_phone'],
      sellerAddress: json['seller_address'] ?? json['sellerAddress'] ?? json['store_address'],
      pickupAddress: json['pickup_address'] ?? json['pickupAddress'],
      buyerName: json['buyer_name'] ?? json['buyerName'],
      customerName: json['customer_name'] ?? json['customerName'] ?? json['buyer_name'] ?? json['buyerName'],
      customerPhone: json['customer_phone'] ?? json['customerPhone'] ?? json['buyer_phone'],
      sellerLatitude: parseNullableDouble(
          json['seller_latitude'] ?? json['sellerLatitude'] ?? json['store_latitude']),
      sellerLongitude: parseNullableDouble(
          json['seller_longitude'] ?? json['sellerLongitude'] ?? json['store_longitude']),
      deliveryLatitude: parseNullableDouble(
          json['delivery_latitude'] ?? json['deliveryLatitude']),
      deliveryLongitude: parseNullableDouble(
          json['delivery_longitude'] ?? json['deliveryLongitude']),
      deliveryInstructions: json['delivery_instructions'] ?? json['deliveryInstructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'delivery_address': deliveryAddress,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_vehicle': driverVehicle,
      'driver_rating': driverRating,
      'assignment_id': assignmentId,
      'created_at': createdAt.toIso8601String(),
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'seller_name': sellerName,
      'seller_phone': sellerPhone,
      'seller_address': sellerAddress,
      'pickup_address': pickupAddress,
      'buyer_name': buyerName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'seller_latitude': sellerLatitude,
      'seller_longitude': sellerLongitude,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_instructions': deliveryInstructions,
    };
  }

  // ==================== Status Helpers ====================
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isPickedUp => status == 'picked_up';
  bool get isDriving => status == 'driving';
  bool get isArrived => status == 'arrived';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  // ==================== Progress Calculation ====================
  double get progress {
    final statuses = [
      'pending', 'confirmed', 'preparing', 'ready',
      'picked_up', 'driving', 'arrived', 'delivered'
    ];
    final index = statuses.indexOf(status);
    if (index == -1) return 0;
    return (index / (statuses.length - 1)) * 100;
  }

  // ==================== Status Display Name ====================
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'picked_up':
        return 'Picked Up';
      case 'driving':
        return 'On The Way';
      case 'arrived':
        return 'Arrived';
      case 'delivered':
        return 'Delivered 🎉';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  // ==================== Status Color (Hex String) ====================
  String get statusColor {
    switch (status) {
      case 'pending':
        return '#F59E0B'; // Orange
      case 'confirmed':
        return '#3B82F6'; // Blue
      case 'preparing':
        return '#8B5CF6'; // Purple
      case 'ready':
        return '#06B6D4'; // Cyan
      case 'picked_up':
        return '#14B8A6'; // Teal
      case 'driving':
        return '#2A7DE1'; // Blue
      case 'arrived':
        return '#6366F1'; // Indigo
      case 'delivered':
        return '#22C55E'; // Green
      case 'cancelled':
        return '#EF4444'; // Red
      default:
        return '#6B7280'; // Gray
    }
  }

  // ==================== Other Helpers ====================
  bool get hasDriver => driverName != null && driverName!.isNotEmpty;
  bool get isActive => !isDelivered && !isCancelled;
  int get itemCount => items.length;
}