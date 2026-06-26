class User {
  final int id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String role;
  final String? profilePicture;
  final bool isVerified;
  final String? location;
  final String? storeName;
  final String? sellerAddress;
  final String? sellerPhone;
  final List<String> deliveryAddresses;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.profilePicture,
    this.isVerified = false,
    this.location,
    this.storeName,
    this.sellerAddress,
    this.sellerPhone,
    this.deliveryAddresses = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      role: json['role'] ?? 'buyer',
      profilePicture: json['profile_picture'] ?? json['profilePicture'],
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      location: json['location'],
      storeName: json['store_name'] ?? json['storeName'],
      sellerAddress: json['seller_address'] ?? json['sellerAddress'] ?? json['address'] ?? json['location'],
      sellerPhone: json['seller_phone'] ?? json['sellerPhone'] ?? json['phone_number'] ?? json['phoneNumber'],
      deliveryAddresses: json['delivery_addresses'] != null
          ? List<String>.from(json['delivery_addresses'])
          : json['deliveryAddresses'] != null
              ? List<String>.from(json['deliveryAddresses'])
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'profile_picture': profilePicture,
      'is_verified': isVerified,
      'location': location,
      'store_name': storeName,
      'seller_address': sellerAddress,
      'seller_phone': sellerPhone,
      'delivery_addresses': deliveryAddresses,
    };
  }

  bool get isBuyer => role == 'buyer';
  bool get isSeller => role == 'seller';
  bool get isDriver => role == 'driver';
  
  String get displayName {
    if (isSeller && storeName != null && storeName!.isNotEmpty) {
      return storeName!;
    }
    return username;
  }
  
  String? get address {
    if (isSeller && sellerAddress != null && sellerAddress!.isNotEmpty) {
      return sellerAddress;
    }
    return location;
  }
}
