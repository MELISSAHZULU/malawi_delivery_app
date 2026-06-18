# update_orders.py
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'malawi_delivery.settings')
django.setup()

from orders.models import Order
from accounts.models import User, SellerProfile

print("=" * 50)
print("UPDATING ORDERS")
print("=" * 50)

# Get the seller
try:
    seller_user = User.objects.get(username='seller1')
    seller = SellerProfile.objects.get(user=seller_user)
    print(f"✅ Seller: {seller.store_name}")
except User.DoesNotExist:
    print("❌ seller1 not found")
    exit()

# Check orders for this seller
orders = Order.objects.filter(seller=seller)
print(f"\nOrders for {seller.store_name}: {orders.count()}")

if orders.count() == 0:
    print("\n⚠️ No orders found for this seller!")
    print("Creating test orders...")
    
    # Get buyer and product
    from accounts.models import BuyerProfile
    from marketplace.models import Product
    
    try:
        buyer_user = User.objects.get(username='buyer1')
        buyer = BuyerProfile.objects.get(user=buyer_user)
    except User.DoesNotExist:
        print("❌ buyer1 not found")
        exit()
    
    product = Product.objects.first()
    if not product:
        print("❌ No products found")
        exit()
    
    # Create orders
    for i in range(3):
        statuses = ['pending', 'confirmed', 'preparing', 'delivered']
        order = Order.objects.create(
            buyer=buyer,
            seller=seller,
            status=statuses[i % 4],
            items=[{
                'product_id': product.id,
                'name': product.name,
                'price': float(product.price),
                'quantity': i + 1
            }],
            subtotal=float(product.price) * (i + 1),
            delivery_fee=1500,
            total=(float(product.price) * (i + 1)) + 1500,
            delivery_address=f'Area {18 + i}, Lilongwe',
            payment_method='paychangu',
            payment_status='completed' if i % 2 == 0 else 'pending'
        )
        print(f"  ✅ Created order: {order.order_number} - {order.status}")

# Show current orders
orders = Order.objects.filter(seller=seller)
print(f"\n📋 Current orders for {seller.store_name}:")
for o in orders:
    print(f"  {o.order_number} - Status: {o.status} - Total: MWK {o.total}")

print("\n✅ Done!")
