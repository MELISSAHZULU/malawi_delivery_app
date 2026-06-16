import 'package:flutter/material.dart';

class TrackingCard extends StatelessWidget {
  final String orderNumber;
  final String status;
  final String eta;

  const TrackingCard({
    Key? key,
    required this.orderNumber,
    required this.status,
    required this.eta,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order #$orderNumber', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Status: $status'),
          Text('ETA: $eta'),
        ],
      ),
    );
  }
}
