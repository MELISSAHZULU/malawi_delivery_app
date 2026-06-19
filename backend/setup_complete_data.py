import os
import django
import random
from datetime import datetime, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'malawi_delivery.settings')
django.setup()

from accounts.models import User, BuyerProfile, SellerProfile, DriverProfile
from marketplace.models import Category, Product
from orders.models import Order
from payments.models import SellerWallet
from django.utils import timezone

print("=" * 60)
print("🚀 CREATING COMPLETE MALAWIDASH DATA")
print("=" * 60)

# ============================================
# 1. CREATE CATEGORIES
# ============================================
print("\n📋 CREATING CATEGORIES...")
categories_data = [
    {'name': 'FOOD', 'icon': '🍕', 'is_active': True},
    {'name': 'GROCERY', 'icon': '🛒', 'is_active': True},
    {'name': 'CRAFTS', 'icon': '🎨', 'is_active': True},
    {'name': 'MARKET', 'icon': '🏪', 'is_active': True},
]

for cat_data in categories_data:
    cat, created = Category.objects.get_or_create(
        name=cat_data['name'],
        defaults={'icon': cat_data['icon'], 'is_active': True}
    )
    print(f"  {'✅ Created' if created else 'ℹ️ Found'} category: {cat.name}")

# Get category objects
food_cat = Category.objects.get(name='FOOD')
grocery_cat = Category.objects.get(name='GROCERY')
crafts_cat = Category.objects.get(name='CRAFTS')
market_cat = Category.objects.get(name='MARKET')

# ============================================
# 2. CREATE BUYERS (CUSTOMERS)
# ============================================
print("\n🛒 CREATING BUYERS...")
buyers_data = [
    {
        'username': 'buyer1', 'password': 'buyer123', 
        'email': 'buyer1@example.com', 'phone': '0999000001',
        'addresses': ['Area 18, Lilongwe', 'City Center, Lilongwe']
    },
    {
        'username': 'chisomo', 'password': 'buyer123', 
        'email': 'chisomo@example.com', 'phone': '0999000002',
        'addresses': ['Area 25, Lilongwe', 'Kanengo, Lilongwe']
    },
    {
        'username': 'grace', 'password': 'buyer123', 
        'email': 'grace@example.com', 'phone': '0999000003',
        'addresses': ['Area 47, Lilongwe', 'Lilongwe City Centre']
    },
    {
        'username': 'david', 'password': 'buyer123', 
        'email': 'david@example.com', 'phone': '0999000004',
        'addresses': ['Blantyre City Centre', 'Limbe, Blantyre']
    },
    {
        'username': 'mary', 'password': 'buyer123', 
        'email': 'mary@example.com', 'phone': '0999000005',
        'addresses': ['Zomba Town', 'Chancellor College, Zomba']
    },
    {
        'username': 'john', 'password': 'buyer123', 
        'email': 'john@example.com', 'phone': '0999000006',
        'addresses': ['Mzuzu City', 'Katoto, Mzuzu']
    },
]

buyers = []
for data in buyers_data:
    user, created = User.objects.get_or_create(
        username=data['username'],
        defaults={
            'email': data['email'],
            'phone_number': data['phone'],
            'role': 'buyer',
            'is_active': True
        }
    )
    if created:
        user.set_password(data['password'])
        user.save()
        buyer_profile, _ = BuyerProfile.objects.get_or_create(
            user=user,
            defaults={'delivery_addresses': data['addresses']}
        )
        print(f"  ✅ Buyer: {user.username} / {data['password']}")
    else:
        print(f"  ℹ️ Buyer already exists: {user.username}")
    buyers.append(user)

# ============================================
# 3. CREATE SELLERS WITH PRODUCTS AND IMAGES
# ============================================
print("\n🏪 CREATING SELLERS WITH PRODUCTS...")

# Helper function for image URLs
def get_food_image(name):
    images = {
        'nsima': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1',
        'chicken': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
        'mandasi': 'https://images.unsplash.com/photo-1559535347-6c5aeac5c3cd',
        'coffee': 'https://images.unsplash.com/photo-1504691342895-6d5c0e1df5af',
        'fish': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2',
        'veggies': 'https://images.unsplash.com/photo-1518843875459-f738682238a0',
        'craft': 'https://images.unsplash.com/photo-1513519245088-0e12902e35f6',
        'fabric': 'https://images.unsplash.com/photo-1523381294911-8d3cead13475',
        'juice': 'https://images.unsplash.com/photo-1526721940322-10fb6e3ae94a',
        'tea': 'https://images.unsplash.com/photo-1556881286-fc6915169721',
        'bread': 'https://images.unsplash.com/photo-1549931319-a545dcf3bc7c',
        'honey': 'https://images.unsplash.com/photo-1587049352846-4a222e784d38',
        'pepper': 'https://images.unsplash.com/photo-1574844834417-bd49cce2c513',
        'fruit': 'https://images.unsplash.com/photo-1505253149613-112d21ef5d9a',
        'soup': 'https://images.unsplash.com/photo-1547592166-23ac45744acd',
        'cookie': 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e',
        'icecream': 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a',
        'pizza': 'https://images.unsplash.com/photo-1513104890138-7c749659a591',
        'burger': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
        'donut': 'https://images.unsplash.com/photo-1551024601-bec78aea704b',
    }
    for key, url in images.items():
        if key in name.lower():
            return url
    return list(images.values())[random.randint(0, len(images)-1)]

# Seller 1: Chambo & Nsima Hub (Food)
print("\n  📍 Chambo & Nsima Hub - Lilongwe")
seller1_user, created = User.objects.get_or_create(
    username='seller1',
    defaults={
        'email': 'seller1@example.com',
        'phone_number': '0999000010',
        'role': 'seller',
        'is_active': True
    }
)
if created:
    seller1_user.set_password('seller123')
    seller1_user.save()
    print("    ✅ Created seller1")
else:
    print("    ℹ️ seller1 already exists")

seller1_profile, _ = SellerProfile.objects.get_or_create(
    user=seller1_user,
    defaults={
        'store_name': 'Chambo & Nsima Hub',
        'store_description': 'Authentic Malawian food made with love and tradition',
        'address': 'Area 18 Shopping Complex, Lilongwe',
        'latitude': -13.9626,
        'longitude': 33.7741,
        'is_active': True,
        'is_approved': True,
        'delivery_fee': 1500
    }
)
wallet1, _ = SellerWallet.objects.get_or_create(seller=seller1_profile)

# Products for Seller 1
products_seller1 = [
    {
        'name': 'Nsima with Fried Lake Chambo',
        'description': 'Fresh fried whole Chambo fish from Cape Maclear, served with two lumps of white corn nsima, tomato-onion gravy, and khwanya sauce.',
        'price': 4800,
        'is_premium': True,
        'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2'
    },
    {
        'name': 'Slow Stewed Local Chicken (Khuku)',
        'description': 'Hard-body free-range local Malawian chicken cooked slowly with natural ginger, garlic, and tomato curry. High energy, rich flavor.',
        'price': 7500,
        'is_premium': True,
        'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38'
    },
    {
        'name': 'Nsima & Ndiwo Special',
        'description': 'Traditional Malawian nsima with fresh ndiwo, served with vegetables and a choice of protein.',
        'price': 3500,
        'is_premium': False,
        'image': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1'
    },
]

for prod_data in products_seller1:
    product, created = Product.objects.get_or_create(
        name=prod_data['name'],
        seller=seller1_profile,
        defaults={
            'description': prod_data['description'],
            'price': prod_data['price'],
            'category': food_cat,
            'stock_quantity': 100,
            'is_available': True,
            'is_premium': prod_data['is_premium'],
            'images': [prod_data['image']],
            'is_featured': True,
        }
    )
    if created:
        print(f"    ✅ Product: {product.name} - MWK {product.price}")

# Seller 2: Mzuzu Coffee Corner (Beverages)
print("\n  📍 Mzuzu Coffee Corner - Mzuzu")
seller2_user, created = User.objects.get_or_create(
    username='seller2',
    defaults={
        'email': 'seller2@example.com',
        'phone_number': '0999000011',
        'role': 'seller',
        'is_active': True
    }
)
if created:
    seller2_user.set_password('seller123')
    seller2_user.save()
    print("    ✅ Created seller2")
else:
    print("    ℹ️ seller2 already exists")

seller2_profile, _ = SellerProfile.objects.get_or_create(
    user=seller2_user,
    defaults={
        'store_name': 'Mzuzu Coffee Corner',
        'store_description': 'Fresh coffee and baked goods from the northern highlands',
        'address': 'Katoto Road Side, Mzuzu',
        'latitude': -11.4565,
        'longitude': 33.8522,
        'is_active': True,
        'is_approved': True,
        'delivery_fee': 1500
    }
)
wallet2, _ = SellerWallet.objects.get_or_create(seller=seller2_profile)

products_seller2 = [
    {
        'name': 'Mzuzu Ground Filter Coffee (250g)',
        'description': 'Medium roast organic ground coffee beans harvested in northern highlands. Rich caramel body with chocolate hints and a smooth finish.',
        'price': 8500,
        'is_premium': True,
        'image': 'https://images.unsplash.com/photo-1504691342895-6d5c0e1df5af'
    },
    {
        'name': 'Bag of 5 Golden Mandasi',
        'description': 'Crispy yet fluffy local sweet fried doughnuts, prepared at dawn and served warm. Essential Malawian breakfast treat.',
        'price': 1500,
        'is_premium': False,
        'image': 'https://images.unsplash.com/photo-1559535347-6c5aeac5c3cd'
    },
    {
        'name': 'Chombe Tea Blend (50 Bags)',
        'description': 'Strong national black tea grown in the fertile Thyolo hills. Perfect hot brew with milk and dark brown sugar.',
        'price': 1900,
        'is_premium': False,
        'image': 'https://images.unsplash.com/photo-1556881286-fc6915169721'
    },
    {
        'name': 'Fresh Honey from Mulanje',
        'description': 'Pure raw honey harvested from the pristine forests of Mount Mulanje. Unfiltered and unpasteurized.',
        'price': 4500,
        'is_premium': True,
        'image': 'https://images.unsplash.com/photo-1587049352846-4a222e784d38'
    },
]

for prod_data in products_seller2:
    product, created = Product.objects.get_or_create(
        name=prod_data['name'],
        seller=seller2_profile,
        defaults={
            'description': prod_data['description'],
            'price': prod_data['price'],
            'category': grocery_cat,
            'stock_quantity': 100,
            'is_available': True,
            'is_premium': prod_data['is_premium'],
            'images': [prod_data['image']],
            'is_featured': True,
        }
    )
    if created:
        print(f"    ✅ Product: {product.name} - MWK {product.price}")

# Seller 3: Limbe Central Market Stall (Groceries)
print("\n  📍 Limbe Central Market Stall - Blantyre")
seller3_user, created = User.objects.get_or_create(
    username='seller3',
    defaults={
        'email': 'seller3@example.com',
        'phone_number': '0999000012',
        'role': 'seller',
        'is_active': True
    }
)
if created:
    seller3_user.set_password('seller123')
    seller3_user.save()
    print("    ✅ Created seller3")
else:
    print("    ℹ️ seller3 already exists")

seller3_profile, _ = SellerProfile.objects.get_or_create(
    user=seller3_user,
    defaults={
        'store_name': 'Limbe Central Market Stall',
        'store_description': 'Fresh produce and local staples from Blantyre\'s best market',
        'address': 'Limbe Market Road, Blantyre',
        'latitude': -15.8267,
        'longitude': 35.0500,
        'is_active': True,
        'is_approved': True,
        'delivery_fee': 1500
    }
)
wallet3, _ = SellerWallet.objects.get_or_create(seller=seller3_profile)

products_seller3 = [
    {
        'name': 'Sobo Squash Syrup - Cherry (2L)',
        'description': 'The iconic Malawian sweet syrup juice found in every home. Simply dilute with cold water to refresh.',
        'price': 3600,
        'is_premium': False,
        'image': 'https://images.unsplash.com/photo-1526721940322-10fb6e3ae94a'
    },
    {
        'name': 'Fresh Vegetable Bundle',
        'description': 'Assorted fresh vegetables including cabbage, tomatoes, onions, and local greens. Sourced directly from local farmers.',
        'price': 2800,
        'is_premium': False,
        'image': 'https://images.unsplash.com/photo-1518843875459-f738682238a0'
    },
    {
        'name': 'Malawian Spice Collection',
        'description': 'Authentic local spices including chili, turmeric, ginger, and the famous Malawian pepper blend.',
        'price': 3200,
        'is_premium': True,
        'image': 'https://images.unsplash.com/photo-1574844834417-bd49cec2c513'
    },
]

for prod_data in products_seller3:
    product, created = Product.objects.get_or_create(
        name=prod_data['name'],
        seller=seller3_profile,
        defaults={
            'description': prod_data['description'],
            'price': prod_data['price'],
            'category': grocery_cat,
            'stock_quantity': 100,
            'is_available': True,
            'is_premium': prod_data['is_premium'],
            'images': [prod_data['image']],
            'is_featured': True,
        }
    )
    if created:
        print(f"    ✅ Product: {product.name} - MWK {product.price}")

# Seller 4: Zomba Plateau Handcrafts (Crafts)
print("\n  📍 Zomba Plateau Handcrafts - Zomba")
seller4_user, created = User.objects.get_or_create(
    username='seller4',
    defaults={
        'email': 'seller4@example.com',
        'phone_number': '0999000013',
        'role': 'seller',
        'is_active': True
    }
)
if created:
    seller4_user.set_password('seller123')
    seller4_user.save()
    print("    ✅ Created seller4")
else:
    print("    ℹ️ seller4 already exists")

seller4_profile, _ = SellerProfile.objects.get_or_create(
    user=seller4_user,
    defaults={
        'store_name': 'Zomba Plateau Handcrafts',
        'store_description': 'Beautiful handcrafted items from the artisans of Zomba Plateau',
        'address': 'Chinyonga Junction, Zomba',
        'latitude': -15.3850,
        'longitude': 35.3310,
        'is_active': True,
        'is_approved': True,
        'delivery_fee': 1500
    }
)
wallet4, _ = SellerWallet.objects.get_or_create(seller=seller4_profile)

products_seller4 = [
    {
        'name': 'Hand-carved Mahogany Hippo',
        'description': 'Expertly shaped Hippopotamus figurine polished to a brilliant crimson finish, craved from single salvaged mahogany tree.',
        'price': 16000,
        'is_premium': True,
        'image': 'https://images.unsplash.com/photo-1513519245088-0e12902e35f6'
    },
    {
        'name': 'Chitenje Wax Print Fabric (6 Yards)',
        'description': 'Beautiful premium 100% heavy cotton print featuring orange and deep emerald floral patterns. Great for tailored suits.',
        'price': 13500,
        'is_premium': True,
        'image': 'https://images.unsplash.com/photo-1523381294911-8d3cead13475'
    },
    {
        'name': 'Handwoven Basket Collection',
        'description': 'Traditional Malawian baskets handwoven from local fibers. Available in various sizes and patterns.',
        'price': 8500,
        'is_premium': False,
        'image': 'https://images.unsplash.com/photo-1513519245088-0e12902e35f6'
    },
]

for prod_data in products_seller4:
    product, created = Product.objects.get_or_create(
        name=prod_data['name'],
        seller=seller4_profile,
        defaults={
            'description': prod_data['description'],
            'price': prod_data['price'],
            'category': crafts_cat,
            'stock_quantity': 100,
            'is_available': True,
            'is_premium': prod_data['is_premium'],
            'images': [prod_data['image']],
            'is_featured': True,
        }
    )
    if created:
        print(f"    ✅ Product: {product.name} - MWK {product.price}")

# ============================================
# 4. CREATE DRIVERS
# ============================================
print("\n🚚 CREATING DRIVERS...")
drivers_data = [
    {'username': 'driver1', 'password': 'driver123', 'email': 'driver1@example.com', 'phone': '0999000020', 'vehicle': 'motorcycle', 'plate': 'MW 1234 A', 'model': 'Yamaha YBR 125'},
    {'username': 'driver2', 'password': 'driver123', 'email': 'driver2@example.com', 'phone': '0999000021', 'vehicle': 'motorcycle', 'plate': 'MW 5678 B', 'model': 'Honda CB 150'},
    {'username': 'driver3', 'password': 'driver123', 'email': 'driver3@example.com', 'phone': '0999000022', 'vehicle': 'car', 'plate': 'MW 9012 C', 'model': 'Toyota Corolla'},
    {'username': 'joseph', 'password': 'driver123', 'email': 'joseph@example.com', 'phone': '0999000023', 'vehicle': 'motorcycle', 'plate': 'MW 3456 D', 'model': 'Suzuki GS 150'},
    {'username': 'mary', 'password': 'driver123', 'email': 'mary@example.com', 'phone': '0999000024', 'vehicle': 'motorcycle', 'plate': 'MW 7890 E', 'model': 'Bajaj Boxer 150'},
]

for data in drivers_data:
    user, created = User.objects.get_or_create(
        username=data['username'],
        defaults={
            'email': data['email'],
            'phone_number': data['phone'],
            'role': 'driver',
            'is_active': True
        }
    )
    if created:
        user.set_password(data['password'])
        user.save()
        DriverProfile.objects.get_or_create(
            user=user,
            defaults={
                'vehicle_type': data['vehicle'],
                'vehicle_plate': data['plate'],
                'is_available': True,
                'is_verified': True
            }
        )
        print(f"  ✅ Driver: {user.username} / {data['password']} - {data['vehicle']}")
    else:
        print(f"  ℹ️ Driver already exists: {user.username}")

# ============================================
# 5. CREATE ORDERS
# ============================================
print("\n📦 CREATING ORDER HISTORY...")

# Create some orders for buyers
order_statuses = ['pending', 'confirmed', 'preparing', 'delivered']
all_sellers = [seller1_profile, seller2_profile, seller3_profile, seller4_profile]

for buyer in buyers[:4]:  # First 4 buyers
    for i in range(2):  # 2 orders per buyer
        seller = random.choice(all_sellers)
        products = Product.objects.filter(seller=seller, is_available=True)
        if products.exists():
            product = random.choice(products)
            quantity = random.randint(1, 3)
            status = order_statuses[i % 4]
            
            order = Order.objects.create(
                buyer=buyer.buyer_profile,
                seller=seller,
                status=status,
                items=[{
                    'product_id': product.id,
                    'name': product.name,
                    'price': float(product.price),
                    'quantity': quantity
                }],
                subtotal=float(product.price) * quantity,
                delivery_fee=1500,
                total=(float(product.price) * quantity) + 1500,
                delivery_address=f'Area {random.randint(10, 50)}, Lilongwe',
                payment_method='paychangu',
                payment_status='completed' if status == 'delivered' else 'pending'
            )
            print(f"  ✅ Order {order.order_number} - {status} - MWK {order.total}")

# ============================================
# SUMMARY
# ============================================
print("\n" + "=" * 60)
print("✅ DATA CREATION COMPLETE!")
print("=" * 60)

print("\n📊 SUMMARY:")
print(f"  👤 Users: {User.objects.count()}")
print(f"  🛒 Buyers: {User.objects.filter(role='buyer').count()}")
print(f"  🏪 Sellers: {User.objects.filter(role='seller').count()}")
print(f"  🚚 Drivers: {User.objects.filter(role='driver').count()}")
print(f"  📦 Products: {Product.objects.count()}")
print(f"  📋 Orders: {Order.objects.count()}")

print("\n📋 TEST CREDENTIALS:")
print("\n🛒 BUYERS:")
print("  buyer1 / buyer123  - Area 18, Lilongwe")
print("  chisomo / buyer123 - Area 25, Lilongwe")
print("  grace / buyer123   - Area 47, Lilongwe")
print("  david / buyer123   - Blantyre")
print("  mary / buyer123    - Zomba")
print("  john / buyer123    - Mzuzu")

print("\n🏪 SELLERS:")
print("  seller1 / seller123 - Chambo & Nsima Hub (Food)")
print("  seller2 / seller123 - Mzuzu Coffee Corner (Beverages)")
print("  seller3 / seller123 - Limbe Central Market (Groceries)")
print("  seller4 / seller123 - Zomba Plateau Handcrafts (Crafts)")

print("\n🚚 DRIVERS:")
print("  driver1 / driver123 - Motorcycle")
print("  driver2 / driver123 - Motorcycle")
print("  driver3 / driver123 - Car")
print("  joseph / driver123  - Motorcycle")
print("  mary / driver123    - Motorcycle")

print("\n" + "=" * 60)
print("🚀 You can now login with any of these accounts!")
