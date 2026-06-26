class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? image;  // ✅ Single image field
  final List<String> images;
  final double rating;
  final String deliveryTime;
  final bool isPremium;
  final bool isAvailable;
  final int sellerId;
  final String sellerName;
  final int stockQuantity;
  final int? categoryId;
  final String? categoryName;
  final String unit;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    this.images = const [],
    this.rating = 0.0,
    this.deliveryTime = '20-30 min',
    this.isPremium = false,
    this.isAvailable = true,
    required this.sellerId,
    required this.sellerName,
    this.stockQuantity = 0,
    this.categoryId,
    this.categoryName,
    this.unit = 'piece',
  });

  String? get imageUrl => image ?? (images.isNotEmpty ? images.first : null);

  bool get hasImage => image != null || images.isNotEmpty;

  factory Product.fromJson(Map<String, dynamic> json) {
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

    List<String> parseImages(dynamic imagesData) {
      if (imagesData == null) return [];
      if (imagesData is List) {
        return imagesData.map((img) => img.toString()).toList();
      }
      if (imagesData is String) {
        return [imagesData];
      }
      return [];
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parsePrice(json['price']),
      image: json['image'],
      images: parseImages(json['images']),
      rating: (json['rating'] ?? 0).toDouble(),
      deliveryTime: '${json['preparation_time'] ?? 15}-${(json['preparation_time'] ?? 15) + 10} min',
      isPremium: json['is_premium'] ?? false,
      isAvailable: json['is_available'] ?? true,
      sellerId: json['seller'] ?? 0,
      sellerName: json['seller_name'] ?? '',
      stockQuantity: json['stock_quantity'] ?? 0,
      categoryId: json['category'],
      categoryName: json['category_name'],
      unit: json['unit'] ?? 'piece',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'images': images,
      'rating': rating,
      'delivery_time': deliveryTime,
      'is_premium': isPremium,
      'is_available': isAvailable,
      'seller': sellerId,
      'seller_name': sellerName,
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'category_name': categoryName,
      'unit': unit,
    };
  }
}
