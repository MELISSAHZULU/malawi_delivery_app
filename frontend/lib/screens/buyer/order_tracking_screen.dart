import 'package:flutter/material.dart';
import '../../utils/formatters.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  int _progress = 60;
  String _status = 'Driving';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Live GPS Dispatch Loop'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0A1A2B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID
            Text(
              'Order: #${widget.orderId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Progress Bar
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF2A7DE1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '$_progress% Complete',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Status Steps
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  _buildStatusStep('Paid', Icons.payment, true),
                  _buildStatusStep('Cooking', Icons.restaurant, true),
                  _buildStatusStep('Driving', Icons.delivery_dining, true),
                  _buildStatusStep('Arrived', Icons.location_on, false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Driver Info
            const Text(
              'DESPATCH DRIVER',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A6478)),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.person, color: Color(0xFF0A1A2B)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Limbani Banda',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'OPERATOR CONTACT',
                            style: TextStyle(fontSize: 12, color: Color(0xFF4A6478)),
                          ),
                          const Text('+265 999 47 18 25'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chat
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.message, color: Color(0xFF2A7DE1)),
                      const SizedBox(width: 8),
                      const Text(
                        'SECURE CHAT WITH LIMBANI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'e.g. Please wrap the Nsima extra hot...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF2A7DE1)),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Complete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showRatingDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F8B4C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Mark Delivery Complete • Leave 5-Star Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String label, IconData icon, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isComplete ? const Color(0xFF0A1A2B) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isComplete ? Colors.white : Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  isComplete ? '✓ Complete' : 'In progress',
                  style: TextStyle(
                    color: isComplete ? Colors.green : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isComplete) const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate your delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your experience with Limbani?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: const Icon(Icons.star_border, size: 32),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for rating! 🇲🇼 Zikomo!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
