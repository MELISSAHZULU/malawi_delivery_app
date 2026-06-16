import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  int _itemCount = 0;
  double _total = 0.0;

  int get itemCount => _itemCount;
  double get total => _total;

  void addItem({double price = 4800}) {
    _itemCount++;
    _total += price;
    notifyListeners();
  }

  void removeItem({double price = 4800}) {
    if (_itemCount > 0) {
      _itemCount--;
      _total -= price;
      notifyListeners();
    }
  }

  void clearCart() {
    _itemCount = 0;
    _total = 0.0;
    notifyListeners();
  }
}
