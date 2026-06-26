import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/offline_queue_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/offline_banner.dart';
import '../../routes/app_routes.dart';
import '../../utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'ALL ITEMS';
  final TextEditingController _searchController = TextEditingController();

  // Category mapping for filtering
  final Map<String, List<String>> _categoryMap = {
    'ALL ITEMS': ['FOOD', 'GROCERY', 'CRAFTS', 'MARKET'],
    'FOOD': ['FOOD'],
    'GROCERY': ['GROCERY'],
    'CRAFTS': ['CRAFTS'],
    'MARKET': ['MARKET'],
  };

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadOrders();
  }

  Future<void> _loadProducts() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
  }

  Future<void> _loadOrders() async {
    await Provider.of<OrderProvider>(context, listen: false).fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final offlineProvider = Provider.of<OfflineQueueProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    // Apply category filter
    final filteredProducts = _getFilteredProducts(productProvider.products);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cartProvider),
            OfflineBanner(queueCount: offlineProvider.queueLength),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProducts,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationGreeting(),
                      const SizedBox(height: 12),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildSpecialOffer(),
                      const SizedBox(height: 16),
                      _buildCategories(),
                      const SizedBox(height: 16),
                      _buildFeaturedItems(filteredProducts, cartProvider),
                      const SizedBox(height: 16),
                      _buildProductsGrid(filteredProducts, cartProvider),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0A1A2B),
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.settings.name == AppRoutes.buyerHome);
          } else if (index == 1) {
            _navigateToTracking(orderProvider);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.orderHistory,
            );
          } else if (index == 3) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.profile,
            );
          }
        },
      ),
    );
  }

  void _navigateToTracking(OrderProvider orderProvider) {
    String orderId = '';
    if (orderProvider.orders.isNotEmpty) {
      orderId = orderProvider.orders.first.id.toString();
    }
    
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.tracking,
      arguments: orderId,
    );
  }

  List<dynamic> _getFilteredProducts(List<dynamic> products) {
    if (_selectedCategory == 'ALL ITEMS') {
      return products;
    }
    final categoryNames = _categoryMap[_selectedCategory] ?? [];
    return products.where((product) {
      final productCategory = product.categoryName?.toUpperCase() ?? '';
      return categoryNames.contains(productCategory);
    }).toList();
  }

  Widget _buildHeader(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
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
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
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

  Widget _buildLocationGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Color(0xFF2A7DE1)),
            SizedBox(width: 4),
            Text(
              'Lilongwe, Area 18',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A1A2B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$greeting, 🦋',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1A2B),
          ),
        ),
        const Text(
          'What are you craving?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.search, color: Color(0xFF5B6F82)),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search food, groceries, crafts...',
                hintStyle: TextStyle(color: Color(0xFF7F8D9E)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              onChanged: (value) {
                Provider.of<ProductProvider>(context, listen: false).searchProducts(value);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                Provider.of<ProductProvider>(context, listen: false).searchProducts('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialOffer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1A2B), Color(0xFF2A7DE1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SPECIAL OFFER',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Free Delivery',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'On your first 3 orders',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.local_offer,
            size: 48,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['ALL ITEMS', 'FOOD', 'GROCERY', 'CRAFTS', 'MARKET'];

    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = categories[index];
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _selectedCategory == categories[index]
                    ? const Color(0xFF0A1A2B)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: _selectedCategory == categories[index]
                      ? Colors.white
                      : Colors.grey.shade600,
                  fontWeight: _selectedCategory == categories[index]
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedItems(List<dynamic> products, CartProvider cartProvider) {
    final featured = products.where((p) => p.isPremium).take(4).toList();

    if (featured.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🔥 Featured Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1A2B),
              ),
            ),
            Text(
              '${products.length} items',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            itemBuilder: (context, index) {
              final product = featured[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: ProductCard(
                  name: product.name,
                  price: product.price,
                  rating: product.rating,
                  deliveryTime: product.deliveryTime,
                  isPremium: product.isPremium,
                  imageUrl: product.imageUrl,  // ✅ Pass image URL
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.productDetail,
                      arguments: {'productId': product.id},
                    );
                  },
                  onAddToCart: () {
                    cartProvider.addItem(price: product.price, name: product.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid(List<dynamic> products, CartProvider cartProvider) {
    if (Provider.of<ProductProvider>(context).isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No products in this category',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          name: product.name,
          price: product.price,
          rating: product.rating,
          deliveryTime: product.deliveryTime,
          isPremium: product.isPremium,
          imageUrl: product.imageUrl,  // ✅ Pass image URL
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: {'productId': product.id},
            );
          },
          onAddToCart: () {
            cartProvider.addItem(price: product.price, name: product.name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart!'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }
}
