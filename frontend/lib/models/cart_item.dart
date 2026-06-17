class CartItem {
  final int productId;
  final String name;
  final double price;
  int quantity;
  final String? imageUrl;
  final int sellerId;
  final String sellerName;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Parse price safely (handle string or double)
    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) {
        final cleaned = price.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    return CartItem(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      price: parsePrice(json['price']),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['image_url'],
      sellerId: json['seller_id'] ?? 0,
      sellerName: json['seller_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'seller_id': sellerId,
      'seller_name': sellerName,
    };
  }

  double get subtotal => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      sellerId: sellerId,
      sellerName: sellerName,
    );
  }
}
