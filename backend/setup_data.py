# setup_data.py
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'malawi_delivery.settings')
django.setup()

from marketplace.models import Category
from accounts.models import User, SellerProfile
from payments.models import SellerWallet
from marketplace.models import Product

print("=" * 50)
print("SETTING UP DATA")
print("=" * 50)

# Create categories
print("\nCreating categories...")
categories = ['FOOD', 'GROCERY', 'CRAFTS', 'MARKET']
for name in categories:
    cat, created = Category.objects.get_or_create(name=name, defaults={'is_active': True})
    print(f"{'  Created' if created else '  Found'} category: {name}")

# Create sellers if none exist
print("\nCreating sellers...")
if SellerProfile.objects.count() == 0:
    sellers_data = [
        {'username': 'seller1', 'store': 'Chambo & Nsima Hub', 'phone': '0999000010'},
        {'username': 'seller2', 'store': 'Mzuzu Coffee Corner', 'phone': '0999000011'},
        {'username': 'seller3', 'store': 'Limbe Central Market', 'phone': '0999000012'},
    ]
    for data in sellers_data:
        user, created = User.objects.get_or_create(
            username=data['username'],
            defaults={
                'email': f"{data['username']}@example.com",
                'phone_number': data['phone'],
                'role': 'seller',
                'is_active': True
            }
        )
        if created:
            user.set_password('seller123')
            user.save()
            print(f"  Created seller: {user.username}")
        
        profile, created = SellerProfile.objects.get_or_create(
            user=user,
            defaults={
                'store_name': data['store'],
                'address': 'Area 18, Lilongwe',
                'latitude': -13.9626,
                'longitude': 33.7741,
                'is_active': True,
                'is_approved': True
            }
        )
        if created:
            print(f"    Created store: {profile.store_name}")
        
        wallet, created = SellerWallet.objects.get_or_create(
            seller=profile,
            defaults={
                'balance': 50000,
                'total_earned': 75000,
                'total_withdrawn': 25000
            }
        )
        if created:
            print(f"    Created wallet: MWK {wallet.balance}")
else:
    print(f"  Found {SellerProfile.objects.count()} sellers")

# Create products
print("\nCreating products...")
sellers = SellerProfile.objects.all()
if sellers.exists():
    food_cat = Category.objects.get(name='FOOD')
    grocery_cat = Category.objects.get(name='GROCERY')
    
    products_data = [
        {'name': 'Nsima with Fried Lake Chambo', 'desc': 'Fresh fried whole Chambo fish.', 'price': 4800, 'category': food_cat, 'seller': sellers[0]},
        {'name': 'Slow Stewed Local Chicken', 'desc': 'Free-range local chicken.', 'price': 7500, 'category': food_cat, 'seller': sellers[0]},
        {'name': 'Bag of 5 Golden Mandasi', 'desc': 'Crispy local sweet doughnuts.', 'price': 1500, 'category': food_cat, 'seller': sellers[0] if sellers.count() > 0 else sellers[0]},
        {'name': 'Mzuzu Ground Filter Coffee', 'desc': 'Organic ground coffee.', 'price': 8500, 'category': grocery_cat, 'seller': sellers[1] if sellers.count() > 1 else sellers[0]},
    ]
    
    for data in products_data:
        product, created = Product.objects.get_or_create(
            name=data['name'],
            seller=data['seller'],
            defaults={
                'description': data['desc'],
                'price': data['price'],
                'category': data['category'],
                'stock_quantity': 100,
                'is_available': True,
                'is_premium': True
            }
        )
        if created:
            print(f"  Created product: {product.name} - MWK {product.price}")

print("\n" + "=" * 50)
print("SUMMARY")
print("=" * 50)
print(f"Categories: {Category.objects.count()}")
print(f"Sellers: {SellerProfile.objects.count()}")
print(f"Products: {Product.objects.count()}")
print(f"Wallets: {SellerWallet.objects.count()}")
print("\n✅ Setup complete!")
