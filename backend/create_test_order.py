# create_test_order.py
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'malawi_delivery.settings')
django.setup()

from accounts.models import User, BuyerProfile, SellerProfile
from orders.models import Order
from marketplace.models import Product
from django.utils import timezone
import random

print("Creating test order...")

# Get or create buyer
try:
    buyer_user = User.objects.get(username='buyer2')
    buyer_profile = BuyerProfile.objects.get(user=buyer_user)
    print(f"✅ Buyer found: {buyer_user.username}")
except User.DoesNotExist:
    print("Creating buyer2...")
    buyer_user = User.objects.create_user(
        username='buyer2',
        email='buyer2@example.com',
        password='buyer123',
        role='buyer',
        phone_number='0888888888',
        is_active=True
    )
    buyer_profile = BuyerProfile.objects.create(user=buyer_user)
    print(f"✅ Created buyer: {buyer_user.username}")

# Get seller
try:
    seller_user = User.objects.get(username='seller2')
    seller_profile = SellerProfile.objects.get(user=seller_user)
    print(f"✅ Seller found: {seller_profile.store_name}")
except User.DoesNotExist:
    print("❌ Seller not found! Creating seller2...")
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

# Get a product
product = Product.objects.first()
if not product:
    print("❌ No products found! Creating a test product...")
    from marketplace.models import Category
    category = Category.objects.first()
    if not category:
        print("❌ No categories found! Creating FOOD category...")
        category = Category.objects.create(name='FOOD', is_active=True)
    product = Product.objects.create(
        seller=seller_profile,
        category=category,
        name='Test Product for Order',
        description='This is a test product',
        price=4800.00,
        stock_quantity=100,
        is_available=True
    )
    print(f"✅ Created product: {product.name}")

# Create an order
print("Creating order...")
order = Order.objects.create(
    buyer=buyer_profile,
    seller=seller_profile,
    status='driving',
    items=[{
        'product_id': product.id,
        'name': product.name,
        'price': float(product.price),
        'quantity': 2
    }],
    subtotal=float(product.price) * 2,
    delivery_fee=1500,
    total=(float(product.price) * 2) + 1500,
    delivery_address='Area 18, Lilongwe',
    payment_method='paychangu',
    payment_status='completed',
    driver=seller_user,
    estimated_delivery_time=timezone.now() + timezone.timedelta(minutes=30)
)

print(f"✅ Order created successfully!")
print(f"   Order Number: {order.order_number}")
print(f"   Order ID: {order.id}")
print(f"   Status: {order.status}")
print(f"   Total: MWK {order.total}")
print(f"   Buyer: {order.buyer.user.username}")
print(f"   Seller: {order.seller.store_name}")
