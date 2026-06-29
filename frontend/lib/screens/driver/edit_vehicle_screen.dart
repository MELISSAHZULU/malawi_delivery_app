import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';

class EditVehicleScreen extends StatefulWidget {
  const EditVehicleScreen({Key? key}) : super(key: key);

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleTypeController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  void _loadDriverData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null && user.isDriver) {
      _vehicleTypeController.text = user.vehicleType ?? 'motorcycle';
      _vehiclePlateController.text = user.vehiclePlate ?? '';
      _vehicleColorController.text = user.vehicleColor ?? '';
      _vehicleModelController.text = user.vehicleModel ?? '';
    }
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehiclePlateController.dispose();
    _vehicleColorController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Vehicle'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveVehicleDetails,
            child: Text(
              _isLoading ? 'Saving...' : 'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : const Color(0xFF2A7DE1),
                fontWeight: FontWeight.bold,
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
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1A2B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Vehicle Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _vehicleTypeController.text.isNotEmpty 
                          ? _vehicleTypeController.text 
                          : 'motorcycle',
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
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
                      onChanged: (value) {
                        setState(() {
                          _vehicleTypeController.text = value!;
                        });
                      },
                      validator: (value) => Validators.validateRequired(value, 'Vehicle Type'),
                    ),
                    const SizedBox(height: 16),

                    // Plate Number
                    TextFormField(
                      controller: _vehiclePlateController,
                      decoration: const InputDecoration(
                        labelText: 'Plate Number',
                        prefixIcon: Icon(Icons.format_list_numbered),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) => Validators.validateRequired(value, 'Plate Number'),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Color
                    TextFormField(
                      controller: _vehicleColorController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Color',
                        prefixIcon: Icon(Icons.color_lens),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) => Validators.validateRequired(value, 'Vehicle Color'),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Model
                    TextFormField(
                      controller: _vehicleModelController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Model',
                        prefixIcon: Icon(Icons.model_training),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) => Validators.validateRequired(value, 'Vehicle Model'),
                    ),
                    const SizedBox(height: 24),

                    // Current info summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Update your vehicle details. This information helps customers identify your vehicle.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
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

  Future<void> _saveVehicleDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final updateData = {
        'vehicle_type': _vehicleTypeController.text.trim(),
        'vehicle_plate': _vehiclePlateController.text.trim(),
        'vehicle_color': _vehicleColorController.text.trim(),
        'vehicle_model': _vehicleModelController.text.trim(),
      };

      print('📤 Updating vehicle details: $updateData');

      final response = await _apiService.updateDriverProfile(updateData);
      
      print('Update vehicle response: $response');

      if (response['success'] == true) {
        await authProvider.loadUser();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vehicle details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['error'] ?? 'Failed to update vehicle details'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating vehicle details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
