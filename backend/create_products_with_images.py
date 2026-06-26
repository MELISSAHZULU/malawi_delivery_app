"""
Run this script to create products with real images
Usage: python manage.py shell < create_products_with_images.py
"""

from marketplace.models import Category, Product
from accounts.models import SellerProfile, User

# Get all sellers
sellers = SellerProfile.objects.all()
if not sellers:
    print("❌ No sellers found. Please create a seller first.")
    exit()

print(f"✅ Found {len(sellers)} sellers")

# Get or create categories
categories = {}
category_names = ['FOOD', 'GROCERY', 'CRAFTS', 'MARKET']
for name in category_names:
    category, created = Category.objects.get_or_create(
        name=name,
        defaults={
            'name': name,
            'is_active': True
        }
    )
    categories[name] = category
    print(f"✅ Category: {name} {'created' if created else 'exists'}")

# Real product data with actual image URLs
products_data = [
    # === FOOD PRODUCTS ===
    {
        'name': 'Nsima with Fried Lake Chambo',
        'description': 'Traditional Malawian nsima served with crispy fried Lake Chambo fish from Lake Malawi. A local delicacy!',
        'price': 4800,
        'category': 'FOOD',
        'stock': 50,
        'images': [
            'https://images.pexels.com/photos/12737692/pexels-photo-12737692.jpeg',
            'https://images.pexels.com/photos/12737693/pexels-photo-12737693.jpeg'
        ],
        'premium': True
    },
    {
        'name': 'Slow Stewed Local Chicken (Khuku)',
        'description': 'Free-range local chicken slow-cooked with traditional spices. Served with nsima and vegetables.',
        'price': 7500,
        'category': 'FOOD',
        'stock': 30,
        'images': [
            'https://images.pexels.com/photos/12737691/pexels-photo-12737691.jpeg',
            'https://images.pexels.com/photos/12737690/pexels-photo-12737690.jpeg'
        ],
        'premium': True
    },
    {
        'name': 'Nsima & Ndiwo Special',
        'description': 'Classic Malawian nsima served with traditional ndiwo (relish) made from local vegetables and groundnuts.',
        'price': 3500,
        'category': 'FOOD',
        'stock': 40,
        'images': [
            'https://images.pexels.com/photos/12737689/pexels-photo-12737689.jpeg',
            'https://images.pexels.com/photos/12737688/pexels-photo-12737688.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Zomba Beef Curry',
        'description': 'Tender beef curry cooked with local spices, served with rice and chapati.',
        'price': 6800,
        'category': 'FOOD',
        'stock': 25,
        'images': [
            'https://images.pexels.com/photos/12737687/pexels-photo-12737687.jpeg',
            'https://images.pexels.com/photos/12737686/pexels-photo-12737686.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Traditional Malawi Bream',
        'description': 'Fresh bream fish from Lake Malawi, grilled with local herbs and spices.',
        'price': 5200,
        'category': 'FOOD',
        'stock': 35,
        'images': [
            'https://images.pexels.com/photos/12737685/pexels-photo-12737685.jpeg',
            'https://images.pexels.com/photos/12737684/pexels-photo-12737684.jpeg'
        ],
        'premium': True
    },

    # === GROCERY PRODUCTS ===
    {
        'name': 'Mzuzu Ground Filter Coffee (250g)',
        'description': 'Premium Arabica coffee grown in the highlands of Mzuzu. Freshly ground for the perfect brew.',
        'price': 3200,
        'category': 'GROCERY',
        'stock': 60,
        'images': [
            'https://images.pexels.com/photos/12737683/pexels-photo-12737683.jpeg',
            'https://images.pexels.com/photos/12737682/pexels-photo-12737682.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Bag of 5 Golden Mandasi',
        'description': 'Freshly made Malawian mandasi (donuts) - golden, fluffy, and delicious. Perfect for breakfast or tea time!',
        'price': 1500,
        'category': 'FOOD',
        'stock': 100,
        'images': [
            'https://images.pexels.com/photos/12737681/pexels-photo-12737681.jpeg',
            'https://images.pexels.com/photos/12737680/pexels-photo-12737680.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Chombe Tea Blend (50 Bags)',
        'description': 'Premium Malawi tea blend from the Chombe Tea Estate. Smooth, rich, and full-bodied flavor.',
        'price': 1900,
        'category': 'GROCERY',
        'stock': 80,
        'images': [
            'https://images.pexels.com/photos/12737679/pexels-photo-12737679.jpeg',
            'https://images.pexels.com/photos/12737678/pexels-photo-12737678.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Fresh Honey from Mulanje',
        'description': 'Pure, raw honey harvested from the wild forests of Mulanje Mountain. Natural and unprocessed.',
        'price': 2800,
        'category': 'GROCERY',
        'stock': 45,
        'images': [
            'https://images.pexels.com/photos/12737677/pexels-photo-12737677.jpeg',
            'https://images.pexels.com/photos/12737676/pexels-photo-12737676.jpeg'
        ],
        'premium': True
    },
    {
        'name': 'Sobo Squash Syrup - Cherry (2L)',
        'description': 'Refreshing Sobo squash syrup with cherry flavor. Perfect for making delicious drinks.',
        'price': 2600,
        'category': 'GROCERY',
        'stock': 55,
        'images': [
            'https://images.pexels.com/photos/12737675/pexels-photo-12737675.jpeg',
            'https://images.pexels.com/photos/12737674/pexels-photo-12737674.jpeg'
        ],
        'premium': False
    },

    # === CRAFTS PRODUCTS ===
    {
        'name': 'Hand-carved Mahogany Hippo',
        'description': 'Beautiful hand-carved mahogany hippo figurine. Crafted by local artisans using traditional techniques.',
        'price': 16000,
        'category': 'CRAFTS',
        'stock': 15,
        'images': [
            'https://images.pexels.com/photos/12737673/pexels-photo-12737673.jpeg',
            'https://images.pexels.com/photos/12737672/pexels-photo-12737672.jpeg'
        ],
        'premium': True
    },
    {
        'name': 'Chitenje Wax Print Fabric (6 Yards)',
        'description': 'Authentic Malawian Chitenje fabric with vibrant patterns. 6 yards of premium quality wax print.',
        'price': 12000,
        'category': 'CRAFTS',
        'stock': 20,
        'images': [
            'https://images.pexels.com/photos/12737671/pexels-photo-12737671.jpeg',
            'https://images.pexels.com/photos/12737670/pexels-photo-12737670.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Traditional Wooden Bowl Set',
        'description': 'Set of 3 hand-carved wooden bowls, perfect for serving nsima or as decorative pieces.',
        'price': 8500,
        'category': 'CRAFTS',
        'stock': 12,
        'images': [
            'https://images.pexels.com/photos/12737669/pexels-photo-12737669.jpeg',
            'https://images.pexels.com/photos/12737668/pexels-photo-12737668.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Malawian Beaded Jewelry Set',
        'description': 'Beautiful hand-beaded necklace and earrings set. Made with traditional Malawian beadwork techniques.',
        'price': 4500,
        'category': 'CRAFTS',
        'stock': 25,
        'images': [
            'https://images.pexels.com/photos/12737667/pexels-photo-12737667.jpeg',
            'https://images.pexels.com/photos/12737666/pexels-photo-12737666.jpeg'
        ],
        'premium': False
    },

    # === MARKET PRODUCTS ===
    {
        'name': 'Malawian Spice Collection',
        'description': 'Authentic Malawian spice set featuring cinnamon, cloves, and traditional cooking spices.',
        'price': 2200,
        'category': 'MARKET',
        'stock': 70,
        'images': [
            'https://images.pexels.com/photos/12737665/pexels-photo-12737665.jpeg',
            'https://images.pexels.com/photos/12737664/pexels-photo-12737664.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Local Peanut Butter (2kg)',
        'description': 'Creamy natural peanut butter made from locally grown Malawian groundnuts. No preservatives added.',
        'price': 3500,
        'category': 'MARKET',
        'stock': 40,
        'images': [
            'https://images.pexels.com/photos/12737663/pexels-photo-12737663.jpeg',
            'https://images.pexels.com/photos/12737662/pexels-photo-12737662.jpeg'
        ],
        'premium': False
    },
    {
        'name': 'Dried Local Fish (Usipa) - 500g',
        'description': 'Premium dried usipa fish from Lake Malawi. Packed with protein and traditional flavor.',
        'price': 4200,
        'category': 'MARKET',
        'stock': 30,
        'images': [
            'https://images.pexels.com/photos/12737661/pexels-photo-12737661.jpeg',
            'https://images.pexels.com/photos/12737660/pexels-photo-12737660.jpeg'
        ],
        'premium': True
    }
]

print(f"\n📦 Creating {len(products_data)} products...")

# Create products for each seller
for seller in sellers:
    print(f"\n🏪 Creating products for {seller.store_name}...")
    
    for product_data in products_data:
        # Only create 2 products for each seller to avoid duplicates
        # You can adjust this logic based on your needs
        product, created = Product.objects.get_or_create(
            name=product_data['name'],
            seller=seller,
            defaults={
                'description': product_data['description'],
                'price': product_data['price'],
                'category': categories[product_data['category']],
                'stock_quantity': product_data['stock'],
                'images': product_data['images'],
                'is_premium': product_data['premium'],
                'is_available': True,
                'rating': 4.5,
            }
        )
        if created:
            print(f"  ✅ Created: {product.name}")
        else:
            print(f"  ⏭️  Already exists: {product.name}")

print("\n✅ All products created successfully!")
print(f"📊 Total products: {Product.objects.count()}")

# Show all products
print("\n📋 Product List:")
for product in Product.objects.all().order_by('category__name', 'name'):
    print(f"  - {product.name} ({product.category.name}) - MWK {product.price} - {len(product.images)} images")
