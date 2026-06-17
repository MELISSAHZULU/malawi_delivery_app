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
    // Handle price that might be a string or double
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

    // Get image from images array if available
    String? getImage(dynamic images) {
      if (images == null) return null;
      if (images is List && images.isNotEmpty) {
        return images[0].toString();
      }
      return null;
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parsePrice(json['price']),
      imageUrl: getImage(json['images']),
      rating: (json['rating'] ?? 0).toDouble(),
      deliveryTime: '${json['preparation_time'] ?? 15}-${(json['preparation_time'] ?? 15) + 10} min',
      isPremium: json['is_premium'] ?? false,
      isAvailable: json['is_available'] ?? true,
      sellerId: json['seller'] ?? 0,
      sellerName: json['seller_name'] ?? '',
      stockQuantity: json['stock_quantity'] ?? 0,
      categoryId: json['category'],
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
