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
  });

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

    return Order(
      id: (json['id'] ?? '').toString(),
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      items: parseItems(json['items']),
      subtotal: parseTotal(json['subtotal']),
      deliveryFee: parseTotal(json['delivery_fee']),
      total: parseTotal(json['total']),
      deliveryAddress: json['delivery_address'] ?? '',
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'])
          : null,
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      sellerName: json['seller_name'] ?? json['store_name'],
      sellerPhone: json['seller_phone'] ?? json['store_phone'],
      sellerAddress: json['seller_address'] ?? json['store_address'],
      pickupAddress: json['pickup_address'],
      buyerName: json['buyer_name'],
      customerName: json['customer_name'] ?? json['buyer_name'],
      customerPhone: json['customer_phone'] ?? json['buyer_phone'],
      sellerLatitude: parseNullableDouble(
          json['seller_latitude'] ?? json['store_latitude']),
      sellerLongitude: parseNullableDouble(
          json['seller_longitude'] ?? json['store_longitude']),
      deliveryLatitude: parseNullableDouble(json['delivery_latitude']),
      deliveryLongitude: parseNullableDouble(json['delivery_longitude']),
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
    final statuses = [
      'pending', 'confirmed', 'preparing', 'ready',
      'picked_up', 'driving', 'arrived', 'delivered'
    ];
    final index = statuses.indexOf(status);
    if (index == -1) return 0;
    return (index / (statuses.length - 1)) * 100;
  }
}