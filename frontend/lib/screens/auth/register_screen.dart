import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Seller fields
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalIdController = TextEditingController();
  
  // Driver fields
  final _vehiclePlateController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  String _selectedVehicleType = 'motorcycle';
  
  String _selectedRole = 'buyer';
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  // For web: use URL fields (since file upload doesn't work on web)
  String _profilePhotoUrl = '';
  String _nationalIdImageUrl = '';
  String _licenseImageUrl = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _vehiclePlateController.dispose();
    _vehicleColorController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  void _showUrlDialog(Function(String) onUrlEntered) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                onUrlEntered(url);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A7DE1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1A2B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Malawi\'s delivery marketplace',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Basic Info
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Username'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => Validators.validateEmail(value),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => Validators.validatePhone(value),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => Validators.validatePassword(value),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'I want to...',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'buyer',
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag, size: 20),
                          SizedBox(width: 8),
                          Text('Buy items (Customer)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'seller',
                      child: Row(
                        children: [
                          Icon(Icons.store, size: 20),
                          SizedBox(width: 8),
                          Text('Sell items (Vendor)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'driver',
                      child: Row(
                        children: [
                          Icon(Icons.delivery_dining, size: 20),
                          SizedBox(width: 8),
                          Text('Deliver items (Driver)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 16),

                // ==================== SELLER FIELDS ====================
                if (_selectedRole == 'seller') ...[
                  const Divider(),
                  const Text(
                    'Store Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1A2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Store Name',
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Store Name'),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Store Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Address'),
                  ),
                  const SizedBox(height: 16),

                  const Divider(),
                  const Text(
                    'Identity Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1A2B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Provide these documents to verify your identity',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Photo URL
                  _buildUrlInput(
                    label: 'Profile Photo URL',
                    url: _profilePhotoUrl,
                    onTap: () => _showUrlDialog((url) {
                      setState(() => _profilePhotoUrl = url);
                    }),
                    onClear: () => setState(() => _profilePhotoUrl = ''),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nationalIdController,
                    decoration: const InputDecoration(
                      labelText: 'National ID Number',
                      prefixIcon: Icon(Icons.assignment_ind),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'National ID'),
                  ),
                  const SizedBox(height: 12),

                  // National ID Image URL
                  _buildUrlInput(
                    label: 'National ID Image URL',
                    url: _nationalIdImageUrl,
                    onTap: () => _showUrlDialog((url) {
                      setState(() => _nationalIdImageUrl = url);
                    }),
                    onClear: () => setState(() => _nationalIdImageUrl = ''),
                  ),
                ],

                // ==================== DRIVER FIELDS ====================
                if (_selectedRole == 'driver') ...[
                  const Divider(),
                  const Text(
                    'Vehicle Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1A2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'motorcycle',
                        child: Row(
                          children: [
                            Icon(Icons.two_wheeler, size: 20),
                            SizedBox(width: 8),
                            Text('Motorcycle'),
                          ],
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'car',
                        child: Row(
                          children: [
                            Icon(Icons.directions_car, size: 20),
                            SizedBox(width: 8),
                            Text('Car'),
                          ],
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'van',
                        child: Row(
                          children: [
                            Icon(Icons.directions_car, size: 20),
                            SizedBox(width: 8),
                            Text('Van'),
                          ],
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'truck',
                        child: Row(
                          children: [
                            Icon(Icons.local_shipping, size: 20),
                            SizedBox(width: 8),
                            Text('Truck'),
                          ],
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'bicycle',
                        child: Row(
                          children: [
                            Icon(Icons.pedal_bike, size: 20),
                            SizedBox(width: 8),
                            Text('Bicycle'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedVehicleType = value!),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _vehiclePlateController,
                    decoration: const InputDecoration(
                      labelText: 'Plate Number',
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Plate Number'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _vehicleColorController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Color',
                      prefixIcon: Icon(Icons.color_lens),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Vehicle Color'),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _vehicleModelController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Model',
                      prefixIcon: Icon(Icons.model_training),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Vehicle Model'),
                  ),
                  const SizedBox(height: 16),

                  const Divider(),
                  const Text(
                    'Identity Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1A2B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Provide these documents to verify your identity',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Photo URL
                  _buildUrlInput(
                    label: 'Profile Photo URL',
                    url: _profilePhotoUrl,
                    onTap: () => _showUrlDialog((url) {
                      setState(() => _profilePhotoUrl = url);
                    }),
                    onClear: () => setState(() => _profilePhotoUrl = ''),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nationalIdController,
                    decoration: const InputDecoration(
                      labelText: 'National ID Number',
                      prefixIcon: Icon(Icons.assignment_ind),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'National ID'),
                  ),
                  const SizedBox(height: 12),

                  // National ID Image URL
                  _buildUrlInput(
                    label: 'National ID Image URL',
                    url: _nationalIdImageUrl,
                    onTap: () => _showUrlDialog((url) {
                      setState(() => _nationalIdImageUrl = url);
                    }),
                    onClear: () => setState(() => _nationalIdImageUrl = ''),
                  ),
                  const SizedBox(height: 12),

                  // Driver License Image URL
                  _buildUrlInput(
                    label: 'Driver License Image URL',
                    url: _licenseImageUrl,
                    onTap: () => _showUrlDialog((url) {
                      setState(() => _licenseImageUrl = url);
                    }),
                    onClear: () => setState(() => _licenseImageUrl = ''),
                  ),
                ],

                const SizedBox(height: 16),

                if (authProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (authProvider.error != null) const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _register(authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A1A2B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrlInput({
    required String label,
    required String url,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasUrl = url.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                image: hasUrl
                    ? DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasUrl
                  ? Icon(
                      Icons.link,
                      color: Colors.grey.shade400,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    hasUrl ? '✅ URL added' : 'Tap to add URL',
                    style: TextStyle(
                      color: hasUrl ? Colors.green : Colors.grey.shade600,
                      fontWeight: hasUrl ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (hasUrl)
                    Text(
                      url.length > 30 ? '${url.substring(0, 30)}...' : url,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            if (hasUrl)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _register(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    // Check if required fields are filled for seller/driver
    if (_selectedRole == 'seller' || _selectedRole == 'driver') {
      if (_profilePhotoUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add a profile photo URL'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (_nationalIdImageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add your National ID image URL'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (_nationalIdController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your National ID number'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    authProvider.clearError();

    try {
      final Map<String, dynamic> userData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password2': _confirmPasswordController.text,
        'phone_number': _phoneController.text.trim(),
        'role': _selectedRole,
      };

      if (_selectedRole == 'seller') {
        userData['store_name'] = _storeNameController.text.trim();
        userData['address'] = _addressController.text.trim();
        userData['national_id'] = _nationalIdController.text.trim();
        userData['profile_photo'] = _profilePhotoUrl;
        userData['national_id_image'] = _nationalIdImageUrl;
      }

      if (_selectedRole == 'driver') {
        userData['vehicle_type'] = _selectedVehicleType;
        userData['vehicle_plate'] = _vehiclePlateController.text.trim();
        userData['vehicle_color'] = _vehicleColorController.text.trim();
        userData['vehicle_model'] = _vehicleModelController.text.trim();
        userData['national_id'] = _nationalIdController.text.trim();
        userData['profile_photo'] = _profilePhotoUrl;
        userData['national_id_image'] = _nationalIdImageUrl;
        userData['license_image'] = _licenseImageUrl;
      }

      print('📝 Registering with URLs: $userData');
      
      // Use the AuthProvider's register method which uses JSON
      final success = await authProvider.register(userData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      print('Registration error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }
}
