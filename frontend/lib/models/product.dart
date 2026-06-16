class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final double rating;
  final String deliveryTime;
  final bool isPremium;
  final bool isAvailable;
  final int sellerId;
  final String sellerName;
  final int stockQuantity;
  final int? categoryId;
  final String? categoryName;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.rating = 0.0,
    this.deliveryTime = '20-30 min',
    this.isPremium = false,
    this.isAvailable = true,
    required this.sellerId,
    required this.sellerName,
    this.stockQuantity = 0,
    this.categoryId,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      rating: (json['rating'] ?? 0).toDouble(),
      deliveryTime: json['delivery_time'] ?? '20-30 min',
      isPremium: json['is_premium'] ?? false,
      isAvailable: json['is_available'] ?? true,
      sellerId: json['seller'] ?? 0,
      sellerName: json['seller_name'] ?? '',
      stockQuantity: json['stock_quantity'] ?? 0,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'rating': rating,
      'delivery_time': deliveryTime,
      'is_premium': isPremium,
      'is_available': isAvailable,
      'seller': sellerId,
      'seller_name': sellerName,
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'category_name': categoryName,
    };
  }
}
