import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/formatters.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shopping Basket'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0A1A2B),
        elevation: 0,
        actions: [
          if (cartProvider.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: cartProvider.clearCart,
            ),
        ],
      ),
      body: cartProvider.itemCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Your basket is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to add items',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.itemCount,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.food_bank),
                          ),
                          title: const Text('Nsima with Fried Lake Chambo'),
                          subtitle: Text(Formatters.currencyFormat(4800)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => cartProvider.removeItem(),
                              ),
                              Text('${cartProvider.itemCount}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => cartProvider.addItem(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Basket Subtotal:'),
                          Text(Formatters.currencyFormat(cartProvider.total)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Moto Delivery Charge:'),
                          Text(Formatters.currencyFormat(1500)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total MWK:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            Formatters.currencyFormat(cartProvider.total + 1500),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF0A1A2B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
                          icon: const Icon(Icons.security),
                          label: const Text('Secure Checkout via PayChangu →'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A1A2B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
