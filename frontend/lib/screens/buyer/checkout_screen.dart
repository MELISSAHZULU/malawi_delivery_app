import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/offline_queue_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/formatters.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedOperator = 'airtel';
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PayChangu Header
            Container(
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
            ),
            const SizedBox(height: 24),

            // Order Summary
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
                    _buildSummaryRow('Moto delivery to Area 18:', 1500),
                    const Divider(),
                    _buildSummaryRow('TOTAL COST:', cartProvider.total + 1500, isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mobile Money Selection
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
            const SizedBox(height: 16),

            // Delivery Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'DELIVERY INDICATOR / LANDMARK DETAILS',
                hintText: 'e.g., Area 18, near Shoprite',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
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
                      : 'Pay MWK ${(cartProvider.total + 1500).toStringAsFixed(0)} securely',
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
            ),
            const SizedBox(height: 16),
            Text(
              '🔒 Your payment is secure and encrypted',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

  void _processPayment() async {
    setState(() => _isLoading = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Payment successful! Order placed.'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to home
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.buyerHome,
      (route) => false,
    );
  }
}
