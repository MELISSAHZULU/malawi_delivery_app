import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class EditShopProfileScreen extends StatefulWidget {
  const EditShopProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditShopProfileScreen> createState() => _EditShopProfileScreenState();
}

class _EditShopProfileScreenState extends State<EditShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _wardController;
  late TextEditingController _sloganController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _storeNameController = TextEditingController(text: user?.storeName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController(text: user?.location ?? '');
    _districtController = TextEditingController(text: 'Lilongwe');
    _wardController = TextEditingController(text: 'Area 18');
    _sloganController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Shop Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0A1A2B),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isSaving ? Colors.grey : const Color(0xFF2A7DE1),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shop Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update your shop details',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Store Name
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Store name required' : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Phone number required' : null,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Address required' : null,
              ),
              const SizedBox(height: 16),

              // District
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'District',
                  prefixIcon: Icon(Icons.map),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'District required' : null,
              ),
              const SizedBox(height: 16),

              // Ward / Area
              TextFormField(
                controller: _wardController,
                decoration: const InputDecoration(
                  labelText: 'Ward / Area',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Ward/Area required' : null,
              ),
              const SizedBox(height: 16),

              // Business Slogan
              TextFormField(
                controller: _sloganController,
                decoration: const InputDecoration(
                  labelText: 'Business Slogan',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1A2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Shop Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'store_name': _storeNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'location': _addressController.text.trim(),
        'address': _addressController.text.trim(),
      };

      final response = await ApiService().updateStore(updateData);
      
      print('Update store response: $response');

      if (response['success'] == true) {
        // Refresh user data
        await Provider.of<AuthProvider>(context, listen: false).loadUser();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Shop profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['error'] ?? 'Failed to update shop profile'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
