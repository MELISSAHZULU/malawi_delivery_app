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
import '../../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'ALL ITEMS';

  final List<Product> _mockProducts = [
    Product(
      id: 1,
      name: 'Nsima with Fried Lake Chambo',
      description: 'Fresh fried whole Chambo fish from Cape Maclear',
      price: 4800,
      rating: 4.8,
      isPremium: true,
    ),
    Product(
      id: 2,
      name: 'Slow Stewed Local Chicken',
      description: 'Hard-body free-range local Malawian chicken',
      price: 7500,
      rating: 4.9,
      isPremium: true,
    ),
    Product(
      id: 3,
      name: 'Bag of 5 Golden Mandasi',
      description: 'Crispy yet fluffy local sweet fried doughnuts',
      price: 1500,
      rating: 4.7,
      isPremium: true,
    ),
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
            // Header
            _buildHeader(),
            // Offline Banner
            OfflineBanner(queueCount: offlineProvider.queueLength),
            // Location
            _buildLocationBar(),
            // Search Bar
            _buildSearchBar(),
            // Categories
            _buildCategories(),
            // Live Tracking
            _buildLiveTracking(),
            // Products Grid
            Expanded(
              child: _buildProductsGrid(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            // Already on home
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.tracking, arguments: 'MW-2843');
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.sellerDashboard);
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: 'Mala', color: Color(0xFF0A1A2B)),
                TextSpan(text: 'Wi', color: Color(0xFF2A7DE1)),
                TextSpan(text: 'Dash', color: Color(0xFF0A1A2B)),
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
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search chambo, tea, shops, sugar...',
            hintStyle: TextStyle(color: const Color(0xFF7F8D9E)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF5B6F82)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) {
            // Implement search
          },
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['ALL ITEMS', 'FOOD', 'GROCERY', 'CRAFTS', 'MARKET'];
    final icons = [Icons.dashboard, Icons.fastfood, Icons.shopping_basket, Icons.brush, Icons.storefront];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryChip(
            label: categories[index],
            icon: icons[index],
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
        distance: '2.3 km',
      ),
    );
  }

  Widget _buildProductsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Commerce Shops',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0A1A2B)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See all →', style: TextStyle(color: Color(0xFF2A7DE1))),
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
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
                  name: product.name,
                  price: product.price,
                  imageUrl: '',
                  rating: product.rating,
                  deliveryTime: '20-30 min',
                  isPremium: product.isPremium,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.productDetail,
                      arguments: {'productId': product.id},
                    );
                  },
                  onAddToCart: () {
                    cartProvider.addItem();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to cart!')),
                    );
                  },
                );
              },
            ),
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
