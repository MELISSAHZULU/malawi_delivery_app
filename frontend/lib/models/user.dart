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
  
  // Driver fields
  final String? vehicleType;
  final String? vehiclePlate;
  final String? vehicleColor;
  final String? vehicleModel;
  final String? vehicleImage;
  final String? nationalId;
  final String? nationalIdImage;
  final String? driverLicense;
  final String? profilePhoto;

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
    this.vehicleType,
    this.vehiclePlate,
    this.vehicleColor,
    this.vehicleModel,
    this.vehicleImage,
    this.nationalId,
    this.nationalIdImage,
    this.driverLicense,
    this.profilePhoto,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // ✅ Extract the actual data - handle nested structure
    final data = json['data'] is Map ? json['data'] : json;
    
    print('📦 Parsing User from JSON: ${data['username']} - Role: ${data['role']}');
    
    return User(
      id: data['id'] ?? 0,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phone_number'] ?? data['phoneNumber'],
      role: data['role'] ?? 'buyer',  // ✅ This should be 'driver'
      profilePicture: data['profile_picture'] ?? data['profilePicture'],
      isVerified: data['is_verified'] ?? data['isVerified'] ?? false,
      location: data['location'],
      storeName: data['store_name'] ?? data['storeName'],
      sellerAddress: data['seller_address'] ?? data['sellerAddress'] ?? data['address'] ?? data['location'],
      sellerPhone: data['seller_phone'] ?? data['sellerPhone'] ?? data['phone_number'] ?? data['phoneNumber'],
      deliveryAddresses: data['delivery_addresses'] != null
          ? List<String>.from(data['delivery_addresses'])
          : data['deliveryAddresses'] != null
              ? List<String>.from(data['deliveryAddresses'])
              : [],
      // Driver fields
      vehicleType: data['vehicle_type'] ?? data['vehicleType'],
      vehiclePlate: data['vehicle_plate'] ?? data['vehiclePlate'],
      vehicleColor: data['vehicle_color'] ?? data['vehicleColor'],
      vehicleModel: data['vehicle_model'] ?? data['vehicleModel'],
      vehicleImage: data['vehicle_image'] ?? data['vehicleImage'],
      nationalId: data['national_id'] ?? data['nationalId'],
      nationalIdImage: data['national_id_image'] ?? data['nationalIdImage'],
      driverLicense: data['driver_license'] ?? data['driverLicense'] ?? data['license_image'],
      profilePhoto: data['profile_photo'] ?? data['profilePhoto'] ?? data['profile_picture'],
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
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'vehicle_color': vehicleColor,
      'vehicle_model': vehicleModel,
      'vehicle_image': vehicleImage,
      'national_id': nationalId,
      'national_id_image': nationalIdImage,
      'driver_license': driverLicense,
      'profile_photo': profilePhoto,
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
