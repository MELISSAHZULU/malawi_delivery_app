import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  void addItem({double price = 4800, String name = 'Nsima with Fried Lake Chambo'}) {
    final existingIndex = _items.indexWhere((item) => item.name == name);
    if (existingIndex != -1) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      _items.add(CartItem(
        productId: DateTime.now().millisecondsSinceEpoch,
        name: name,
        price: price,
        quantity: 1,
        sellerId: 1,
        sellerName: 'Chambo & Nsima Hub',
      ));
    }
    notifyListeners();
  }

  void removeItem({double price = 4800, String name = 'Nsima with Fried Lake Chambo'}) {
    final existingIndex = _items.indexWhere((item) => item.name == name);
    if (existingIndex != -1) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity - 1,
        );
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
      notifyListeners();
    }
  }

  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity - 1,
        );
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getOrderItems() {
    return _items.map((item) => item.toJson()).toList();
  }
}
