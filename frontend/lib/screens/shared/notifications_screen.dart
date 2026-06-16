import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Order Delivered!',
      'body': 'Your order #MW-2843 has been delivered successfully.',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'read': false,
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'id': 2,
      'title': 'Driver is on the way',
      'body': 'Limbani is heading to your location with your order.',
      'time': DateTime.now().subtract(const Duration(minutes: 30)),
      'read': false,
      'icon': Icons.delivery_dining,
      'color': Colors.blue,
    },
    {
      'id': 3,
      'title': 'Order Confirmed',
      'body': 'Your order #MW-2842 has been confirmed by the seller.',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'read': true,
      'icon': Icons.check_circle_outline,
      'color': Colors.orange,
    },
    {
      'id': 4,
      'title': 'Special Offer!',
      'body': 'Get 20% off on your next order from Chambo & Nsima Hub.',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'read': true,
      'icon': Icons.local_offer,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !n['read']))
            TextButton(
              onPressed: () {
                // Mark all as read
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you about your orders',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: notification['read'] ? Colors.white : Colors.blue.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification['color'].withOpacity(0.1),
                      child: Icon(
                        notification['icon'],
                        color: notification['color'],
                      ),
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['read'] ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['body']),
                        Text(
                          _timeAgo(notification['time']),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    trailing: notification['read']
                        ? null
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () {
                      setState(() {
                        _notifications[index]['read'] = true;
                      });
                    },
                  ),
                );
              },
            ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
