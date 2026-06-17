import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'malawi_delivery.settings')
django.setup()

from accounts.models import User, BuyerProfile, SellerProfile, DriverProfile
from payments.models import SellerWallet

print("=" * 50)
print("CREATING ALL USERS")
print("=" * 50)

# ============ BUYERS ============
print("\n📋 CREATING BUYERS...")
buyers = [
    {'username': 'buyer1', 'password': 'buyer123', 'email': 'buyer1@example.com', 'phone': '0999000001'},
    {'username': 'buyer2', 'password': 'buyer123', 'email': 'buyer2@example.com', 'phone': '0999000002'},
    {'username': 'chisomo', 'password': 'buyer123', 'email': 'chisomo@example.com', 'phone': '0999000003'},
    {'username': 'grace', 'password': 'buyer123', 'email': 'grace@example.com', 'phone': '0999000004'},
]

for data in buyers:
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
        BuyerProfile.objects.get_or_create(user=user)
        print(f"  ✅ Buyer: {user.username} / {data['password']}")
    else:
        print(f"  ℹ️ Buyer already exists: {user.username}")

# ============ SELLERS ============
print("\n📋 CREATING SELLERS...")
sellers = [
    {'username': 'seller1', 'password': 'seller123', 'email': 'seller1@example.com', 'phone': '0999000010', 'store': 'Chambo & Nsima Hub'},
    {'username': 'seller2', 'password': 'seller123', 'email': 'seller2@example.com', 'phone': '0999000011', 'store': 'Mzuzu Coffee Corner'},
    {'username': 'seller3', 'password': 'seller123', 'email': 'seller3@example.com', 'phone': '0999000012', 'store': 'Limbe Central Market'},
]

for data in sellers:
    user, created = User.objects.get_or_create(
        username=data['username'],
        defaults={
            'email': data['email'],
            'phone_number': data['phone'],
            'role': 'seller',
            'is_active': True
        }
    )
    if created:
        user.set_password(data['password'])
        user.save()
        print(f"  ✅ Seller: {user.username} / {data['password']}")
    else:
        print(f"  ℹ️ Seller already exists: {user.username}")
    
    # Create seller profile
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
        print(f"    ✅ Store: {profile.store_name}")
    
    # Create wallet
    wallet, created = SellerWallet.objects.get_or_create(
        seller=profile,
        defaults={
            'balance': 50000,
            'total_earned': 75000,
            'total_withdrawn': 25000
        }
    )
    if created:
        print(f"    ✅ Wallet: MWK {wallet.balance}")

# ============ DRIVERS ============
print("\n📋 CREATING DRIVERS...")
drivers = [
    {'username': 'driver1', 'password': 'driver123', 'email': 'driver1@example.com', 'phone': '0999000020', 'vehicle': 'motorcycle', 'plate': 'MW 1234 A'},
    {'username': 'driver2', 'password': 'driver123', 'email': 'driver2@example.com', 'phone': '0999000021', 'vehicle': 'motorcycle', 'plate': 'MW 5678 B'},
    {'username': 'driver3', 'password': 'driver123', 'email': 'driver3@example.com', 'phone': '0999000022', 'vehicle': 'car', 'plate': 'MW 9012 C'},
]

for data in drivers:
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
        print(f"  ✅ Driver: {user.username} / {data['password']}")
    else:
        print(f"  ℹ️ Driver already exists: {user.username}")
    
    # Create driver profile
    profile, created = DriverProfile.objects.get_or_create(
        user=user,
        defaults={
            'vehicle_type': data['vehicle'],
            'vehicle_plate': data['plate'],
            'is_available': True,
            'is_verified': True
        }
    )
    if created:
        print(f"    ✅ Vehicle: {data['vehicle']} - {data['plate']}")

print("\n" + "=" * 50)
print("SUMMARY")
print("=" * 50)
print(f"Buyers: {User.objects.filter(role='buyer').count()}")
print(f"Sellers: {User.objects.filter(role='seller').count()}")
print(f"Drivers: {User.objects.filter(role='driver').count()}")
print(f"Wallets: {SellerWallet.objects.count()}")
print("\n✅ All users created!")

print("\n📋 TEST CREDENTIALS:")
print("\n🛒 BUYERS:")
print("  buyer1 / buyer123")
print("  buyer2 / buyer123")
print("  chisomo / buyer123")
print("  grace / buyer123")
print("\n🏪 SELLERS:")
print("  seller1 / seller123")
print("  seller2 / seller123")
print("  seller3 / seller123")
print("\n🚚 DRIVERS:")
print("  driver1 / driver123")
print("  driver2 / driver123")
print("  driver3 / driver123")
