import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final int queueCount;

  const OfflineBanner({Key? key, required this.queueCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: queueCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            queueCount > 0 ? Icons.sync_problem : Icons.check_circle,
            color: queueCount > 0 ? Colors.orange : Colors.green,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              queueCount > 0
                  ? 'Offline: $queueCount items pending'
                  : 'Offline cache ready',
            ),
          ),
        ],
      ),
    );
  }
}
