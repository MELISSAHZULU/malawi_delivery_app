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
    this.deliveryAddresses = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'buyer',
      profilePicture: json['profile_picture'],
      isVerified: json['is_verified'] ?? false,
      location: json['location'],
      storeName: json['store_name'],
      deliveryAddresses: json['delivery_addresses'] != null
          ? List<String>.from(json['delivery_addresses'])
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
      'delivery_addresses': deliveryAddresses,
    };
  }

  bool get isBuyer => role == 'buyer';
  bool get isSeller => role == 'seller';
  bool get isDriver => role == 'driver';
}
