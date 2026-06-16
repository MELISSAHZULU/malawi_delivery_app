import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'MWK ',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('MMM d, y');
  static final DateFormat _timeFormat = DateFormat('h:mm a');

  static String currencyFormat(double amount) {
    return _currencyFormat.format(amount);
  }

  static String dateFormat(DateTime date) {
    return _dateFormat.format(date);
  }

  static String timeFormat(DateTime time) {
    return _timeFormat.format(time);
  }

  static String dateTimeFormat(DateTime dateTime) {
    return '${dateFormat(dateTime)} at ${timeFormat(dateTime)}';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    }
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    }
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    }
    return 'Just now';
  }

  static String orderStatusDisplay(String status) {
    final map = {
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready': 'Ready',
      'picked_up': 'Picked Up',
      'driving': 'Driving',
      'arrived': 'Arrived',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };
    return map[status] ?? status;
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
