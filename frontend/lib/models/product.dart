class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final bool isPremium;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.rating = 0.0,
    this.isPremium = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      isPremium: json['is_premium'] ?? false,
    );
  }
}
