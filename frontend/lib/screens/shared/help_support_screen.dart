import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFAQ(
            'How do I place an order?',
            'Browse products, add to cart, proceed to checkout, and confirm your order.',
          ),
          _buildFAQ(
            'How can I track my order?',
            'Go to the Tracking tab in the bottom navigation to see real-time updates.',
          ),
          _buildFAQ(
            'What payment methods are accepted?',
            'We accept PayChangu via Airtel Money and TNM Mpamba.',
          ),
          _buildFAQ(
            'How long does delivery take?',
            'Delivery typically takes 20-45 minutes depending on your location.',
          ),
          const SizedBox(height: 24),

          // Contact Section
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF2A7DE1)),
              title: const Text('Call Us'),
              subtitle: const Text('+265 999 123 456'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF2A7DE1)),
              title: const Text('Email Us'),
              subtitle: const Text('support@malawidash.com'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF2A7DE1)),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 24/7'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),

          // Report Issue
          const Text(
            'Report an Issue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.report_problem),
              label: const Text('Report a Problem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
