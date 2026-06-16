import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF0A1A2B),
      unselectedItemColor: Colors.grey.shade600,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'BUY'),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'TRACK'),
        BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'SELL GOODS'),
      ],
      onTap: onTap,
    );
  }
}
