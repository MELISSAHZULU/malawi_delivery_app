import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

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
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedRole = 'buyer';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0A1A2B),
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

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Username'),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => Validators.validateEmail(value),
                ),
                const SizedBox(height: 16),

                // Phone
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

                // Password
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

                // Confirm Password
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

                // Role Selection
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'I want to...',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'buyer', child: Text('Buy items (Customer)')),
                    DropdownMenuItem(value: 'seller', child: Text('Sell items (Vendor)')),
                    DropdownMenuItem(value: 'driver', child: Text('Deliver items (Driver)')),
                  ],
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 16),

                // Seller-specific fields
                if (_selectedRole == 'seller') ...[
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
                ],

                // Error message
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

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final userData = {
                                'username': _usernameController.text,
                                'email': _emailController.text,
                                'password': _passwordController.text,
                                'role': _selectedRole,
                                'phone_number': _phoneController.text,
                                'store_name': _storeNameController.text,
                                'address': _addressController.text,
                              };
                              final success = await authProvider.register(userData);
                              if (success && mounted) {
                                // Navigate based on role
                                final user = authProvider.user;
                                if (user != null) {
                                  String route;
                                  if (user.isBuyer) {
                                    route = AppRoutes.buyerHome;
                                  } else if (user.isSeller) {
                                    route = AppRoutes.sellerHome;
                                  } else if (user.isDriver) {
                                    route = AppRoutes.driverHome;
                                  } else {
                                    route = AppRoutes.buyerHome;
                                  }
                                  Navigator.pushReplacementNamed(context, route);
                                }
                              }
                            }
                          },
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Account', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Login link
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
}
