import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/tracking_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../providers/cart_provider.dart';
import '../../providers/offline_queue_provider.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'ALL ITEMS';

  final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': 1,
      'name': 'Nsima with Fried Lake Chambo',
      'description': 'Fresh fried whole Chambo fish from Cape Maclear',
      'price': 4800,
      'rating': 4.8,
      'deliveryTime': '20-30 min',
      'isPremium': true,
    },
    {
      'id': 2,
      'name': 'Slow Stewed Local Chicken',
      'description': 'Hard-body free-range local Malawian chicken',
      'price': 7500,
      'rating': 4.9,
      'deliveryTime': '30-40 min',
      'isPremium': true,
    },
    {
      'id': 3,
      'name': 'Bag of 5 Golden Mandasi',
      'description': 'Crispy yet fluffy local sweet fried doughnuts',
      'price': 1500,
      'rating': 4.7,
      'deliveryTime': '10-15 min',
      'isPremium': true,
    },
    {
      'id': 4,
      'name': 'Mzuzu Ground Filter Coffee',
      'description': 'Medium roast organic ground coffee beans',
      'price': 8500,
      'rating': 4.9,
      'deliveryTime': '5-10 min',
      'isPremium': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final offlineProvider = Provider.of<OfflineQueueProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cartProvider),
            OfflineBanner(queueCount: offlineProvider.queueLength),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationBar(),
                    _buildSearchBar(),
                    _buildCategories(),
                    _buildLiveTracking(),
                    _buildProductsGrid(cartProvider),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.tracking, arguments: 'MW-2843');
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.sellerHome);
          }
        },
      ),
    );
  }

  Widget _buildHeader(CartProvider cartProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: 'Mala', style: TextStyle(color: Color(0xFF0A1A2B))),
                TextSpan(text: 'Wi', style: TextStyle(color: Color(0xFF2A7DE1))),
                TextSpan(text: 'Dash', style: TextStyle(color: Color(0xFF0A1A2B))),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.accessibility_new, color: Color(0xFF2A7DE1)),
                onPressed: () => _showA11ySettings(context),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 18, color: Color(0xFF2A7DE1)),
          const SizedBox(width: 4),
          const Text(
            'DELIVERY LOCATION',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A6478)),
          ),
          const SizedBox(width: 8),
          const Text(
            'Lilongwe / Area 18',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: Color(0xFF2A7DE1)),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search chambo, tea, shops, sugar...',
            hintStyle: TextStyle(color: Color(0xFF7F8D9E)),
            prefixIcon: Icon(Icons.search, color: Color(0xFF5B6F82)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['ALL ITEMS', 'FOOD', 'GROCERY', 'CRAFTS', 'MARKET'];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryChip(
            label: categories[index],
            isActive: _selectedCategory == categories[index],
            onTap: () => setState(() => _selectedCategory = categories[index]),
          );
        },
      ),
    );
  }

  Widget _buildLiveTracking() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TrackingCard(
        orderNumber: 'MW-2843',
        status: 'On the way',
        eta: '12 min',
      ),
    );
  }

  Widget _buildProductsGrid(CartProvider cartProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CHOOSE ITEMS FOR PURCHASE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A6478),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See all →', style: TextStyle(color: Color(0xFF2A7DE1))),
              ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: _mockProducts.length,
            itemBuilder: (context, index) {
              final product = _mockProducts[index];
              return ProductCard(
                name: product['name'],
                price: product['price'].toDouble(),
                rating: product['rating'].toDouble(),
                deliveryTime: product['deliveryTime'],
                isPremium: product['isPremium'],
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.productDetail,
                    arguments: {'productId': product['id']},
                  );
                },
                onAddToCart: () {
                  cartProvider.addItem(price: product['price'].toDouble());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product['name']} added to cart!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showA11ySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Accessibility Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('High Contrast Mode'),
              value: false,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Large Text'),
              value: false,
              onChanged: (v) {},
            ),
          ],
        ),
      ),
    );
  }
}
