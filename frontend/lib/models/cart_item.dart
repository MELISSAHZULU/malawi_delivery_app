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
    return CartItem(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
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
