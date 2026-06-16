# setup_data.py
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'malawi_delivery.settings')
django.setup()

from marketplace.models import Category, Product
from accounts.models import User, SellerProfile

print("Setting up data...")

# Create categories
categories = ['FOOD', 'GROCERY', 'CRAFTS', 'MARKET']
for name in categories:
    category, created = Category.objects.get_or_create(
        name=name,
        defaults={'is_active': True}
    )
    if created:
        print(f"✅ Created category: {name}")
    else:
        print(f"ℹ️ Category already exists: {name}")

# Get or create seller
try:
    seller_user = User.objects.get(username='seller2')
    seller_profile = SellerProfile.objects.get(user=seller_user)
    print(f"✅ Seller found: {seller_profile.store_name}")
except User.DoesNotExist:
    print("Creating seller2...")
    seller_user = User.objects.create_user(
        username='seller2',
        email='seller2@example.com',
        password='seller123',
        role='seller',
        phone_number='0999999999',
        is_active=True
    )
    seller_profile = SellerProfile.objects.create(
        user=seller_user,
        store_name='My Store Malawi',
        address='Area 18, Lilongwe',
        latitude=-13.9626,
        longitude=33.7741,
        is_active=True,
        is_approved=True
    )
    print(f"✅ Created seller: {seller_user.username}")

# Create a test product
category = Category.objects.first()
if category:
    product, created = Product.objects.get_or_create(
        name='Nsima with Fried Lake Chambo',
        defaults={
            'seller': seller_profile,
            'category': category,
            'description': 'Fresh fried whole Chambo fish from Cape Maclear',
            'price': 4800.00,
            'stock_quantity': 100,
            'is_available': True,
            'is_premium': True
        }
    )
    if created:
        print(f"✅ Created product: {product.name}")
    else:
        print(f"ℹ️ Product already exists: {product.name}")
else:
    print("❌ No category found!")

print("Done!")
