"""
Script to create a product with image upload
Run: python manage.py shell < upload_product.py
"""

import os
from django.core.files import File
from marketplace.models import Category, Product
from accounts.models import SellerProfile
import urllib.request

# Get first seller
seller = SellerProfile.objects.first()
if not seller:
    print("❌ No seller found! Please create a seller first.")
    exit()

print(f"✅ Seller: {seller.store_name}")

# Get or create category
category, created = Category.objects.get_or_create(
    name='FOOD',
    defaults={'is_active': True}
)
print(f"✅ Category: {category.name}")

# Create media directory if it doesn't exist
os.makedirs('media/products', exist_ok=True)

# Download a sample image (you can change this URL)
image_url = 'https://images.pexels.com/photos/12737687/pexels-photo-12737687.jpeg'
image_path = 'media/products/pizza_sample.jpg'

try:
    urllib.request.urlretrieve(image_url, image_path)
    print(f"✅ Downloaded image to {image_path}")
except Exception as e:
    print(f"❌ Error downloading image: {e}")
    image_path = None

# Create product
product = Product.objects.create(
    name='Homemade Air Fryer Pizza',
    description='Air fryer homemade pizza. Crusty out, soft and chewy in. The cheese melts perfectly.',
    price=40000,
    category=category,
    seller=seller,
    stock_quantity=100,
    is_available=True,
    is_premium=False,
    preparation_time=15,
)

# Attach image if available
if image_path and os.path.exists(image_path):
    with open(image_path, 'rb') as f:
        product.image.save('pizza.jpg', File(f), save=True)
    print(f"✅ Image attached to product: {product.image.url}")

print(f"\n✅ Product created successfully!")
print(f"   Name: {product.name}")
print(f"   Price: MWK {product.price}")
print(f"   Category: {product.category.name}")
print(f"   Image: {product.image_url}")
print(f"   Product ID: {product.id}")
