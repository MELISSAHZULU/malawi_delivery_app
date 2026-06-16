// Just the MerchandiseTab part - only update the MerchandiseTab class

class MerchandiseTab extends StatefulWidget {
  const MerchandiseTab({Key? key}) : super(key: key);

  @override
  State<MerchandiseTab> createState() => _MerchandiseTabState();
}

class _MerchandiseTabState extends State<MerchandiseTab> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _classification = 'FOOD';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final sellerProducts = productProvider.products;

    print('MerchandiseTab build - products: ${sellerProducts.length}');

    return RefreshIndicator(
      onRefresh: () => productProvider.fetchProducts(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Product Form (keep existing)
            // ... (existing code)
          ],
        ),
      ),
    );
  }
}
