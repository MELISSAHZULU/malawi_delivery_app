// lib/screens/buyer/checkout_screen.dart (UPDATED)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/offline_queue_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/address_picker_dialog.dart';
import '../../widgets/delivery_instructions_field.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedOperator = 'airtel';
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isLoading = false;
  String _selectedRegion = 'Lilongwe';
  String _selectedArea = 'Area 18';
  
  final List<String> _regions = ['Lilongwe', 'Blantyre', 'Zomba', 'Mzuzu'];
  final Map<String, List<String>> _areas = {
    'Lilongwe': ['Area 18', 'Area 25', 'Area 47', 'Kanengo', 'Lilongwe City Center'],
    'Blantyre': ['Chichiri', 'Limbe', 'Ginnery Corner', 'Blantyre City Center'],
    'Zomba': ['Zomba City Center', 'Chancellor College', 'Zomba Central'],
    'Mzuzu': ['Mzuzu City Center', 'Katoto', 'Luwinga', 'Area 1'],
  };

  double _deliveryFee = 1500;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final offlineProvider = Provider.of<OfflineQueueProvider>(context);

    if (cartProvider.itemCount == 0 && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PayChangu Header
            _buildPayChanguHeader(),
            const SizedBox(height: 24),

            // Order Summary
            _buildOrderSummary(cartProvider),
            const SizedBox(height: 24),

            // Delivery Address Section (NEW)
            _buildDeliverySection(),
            const SizedBox(height: 24),

            // Mobile Money Selection
            _buildMobileMoneySection(),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'WALLET PHONE ACCOUNT (+265)',
                prefixText: '+265 ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Pay Button
            _buildPayButton(cartProvider),
            const SizedBox(height: 16),
            
            // Security Note
            _buildSecurityNote(),
          ],
        ),
      ),
    );
  }

  // ==================== NEW DELIVERY SECTION ====================
  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF2A7DE1)),
              const SizedBox(width: 8),
              const Text(
                'DELIVERY LOCATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Region Dropdown
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: const InputDecoration(
              labelText: 'Region',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _regions.map((region) {
              return DropdownMenuItem(value: region, child: Text(region));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRegion = value!;
                _selectedArea = _areas[_selectedRegion]?.first ?? '';
                _updateDeliveryFee();
              });
            },
          ),
          const SizedBox(height: 12),

          // Area Dropdown
          DropdownButtonFormField<String>(
            value: _selectedArea,
            decoration: const InputDecoration(
              labelText: 'Area / Location',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: (_areas[_selectedRegion] ?? []).map((area) {
              return DropdownMenuItem(value: area, child: Text(area));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedArea = value!;
                _updateDeliveryFee();
              });
            },
          ),
          const SizedBox(height: 12),

          // Detailed Address
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Detailed Address / Landmark',
              hintText: 'e.g., House #123, near Shoprite, next to the church',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
          ),
          const SizedBox(height: 12),

          // Delivery Instructions (NEW)
          DeliveryInstructionsField(
            controller: _instructionsController,
            hintText: 'e.g., Leave at gate, ring bell, call on arrival',
          ),
          
          // Delivery Fee Display
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.motorcycle, color: Color(0xFF2A7DE1)),
                    const SizedBox(width: 8),
                    const Text(
                      'Delivery Fee:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  Formatters.currencyFormat(_deliveryFee),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0A1A2B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateDeliveryFee() {
    // Base fee is 1500, adjust based on distance (simplified)
    // In production, this would call the backend to calculate based on actual distance
    final baseFee = 1500.0;
    final areaMultiplier = _areas[_selectedRegion]?.indexOf(_selectedArea) ?? 0;
    final additional = (areaMultiplier * 200).toDouble();
    setState(() {
      _deliveryFee = baseFee + additional;
    });
  }

  // ==================== EXISTING METHODS (UPDATED) ====================
  Widget _buildPayChanguHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Color(0xFF2A7DE1), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PayChangu Secure Gateway',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Simulating Malawi Local Mobile Money Networks',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MALAWIAN KHACHA BILL SUMMARY',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF4A6478),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Basket Items Cost:', cartProvider.total),
                _buildSummaryRow('Delivery Fee:', _deliveryFee),
                const Divider(),
                _buildSummaryRow('TOTAL COST:', cartProvider.total + _deliveryFee, isTotal: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            Formatters.currencyFormat(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? const Color(0xFF0A1A2B) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMoneySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHOOSE MOBILE OPERATOR WALLET',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF4A6478),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOperatorCard('Airtel Money', Icons.signal_cellular_alt, 'airtel'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOperatorCard('TNM Mpamba', Icons.signal_cellular_4_bar, 'tnm'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperatorCard(String name, IconData icon, String value) {
    final isSelected = _selectedOperator == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedOperator = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.blue : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(CartProvider cartProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _processPayment,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.lock_outline),
        label: Text(
          _isLoading
              ? 'Processing...'
              : 'Pay MWK ${(cartProvider.total + _deliveryFee).toStringAsFixed(0)} securely',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A1A2B),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Text(
      '🔒 Your payment is secure and encrypted',
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ==================== UPDATED PAYMENT PROCESS ====================
  void _processPayment() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your detailed delivery address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final offlineProvider = Provider.of<OfflineQueueProvider>(context, listen: false);

    try {
      // Build full delivery address
      final fullAddress = '$_selectedArea, $_selectedRegion - ${_addressController.text}';
      
      // Prepare order data with location info
      final orderData = {
        'items': cartProvider.getOrderItems(),
        'subtotal': cartProvider.total,
        'delivery_fee': _deliveryFee,
        'total': cartProvider.total + _deliveryFee,
        'delivery_address': fullAddress,
        'delivery_instructions': _instructionsController.text,
        'region': _selectedRegion,
        'area': _selectedArea,
        'payment_method': 'paychangu',
        'mobile_number': _phoneController.text,
        'operator': _selectedOperator,
      };

      await Future.delayed(const Duration(seconds: 2));

      final success = await orderProvider.createOrder(orderData);

      if (success) {
        cartProvider.clearCart();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Order placed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          final orderId = orderProvider.currentOrder?.id ?? 'MW-2843';
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.tracking,
            arguments: orderId,
          );
        }
      } else {
        await offlineProvider.addToQueue(orderData);
        cartProvider.clearCart();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📡 Order saved offline. Will sync when online.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
        }
      }
    } catch (e) {
      print('Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}