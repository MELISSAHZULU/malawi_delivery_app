import 'cart_item.dart';

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String? driverName;
  final String? driverPhone;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;
  final String? paymentStatus;
  final String? paymentMethod;

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
    required this.createdAt,
    this.estimatedDeliveryTime,
    this.paymentStatus,
    this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      items: (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      deliveryAddress: json['delivery_address'] ?? '',
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'])
          : null,
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
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
      'created_at': createdAt.toIso8601String(),
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isPickedUp => status == 'picked_up';
  bool get isDriving => status == 'driving';
  bool get isArrived => status == 'arrived';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  double get progress {
    final statuses = ['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'driving', 'arrived', 'delivered'];
    final index = statuses.indexOf(status);
    if (index == -1) return 0;
    return (index / (statuses.length - 1)) * 100;
  }
}
