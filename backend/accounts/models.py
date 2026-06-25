# backend/accounts/models.py

from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    ROLE_CHOICES = (
        ('buyer', 'Buyer'),
        ('seller', 'Seller'),
        ('driver', 'Driver'),
    )
    
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='buyer')
    phone_number = models.CharField(max_length=15, unique=True, null=True, blank=True)
    profile_picture = models.ImageField(upload_to='profiles/', null=True, blank=True)
    is_verified = models.BooleanField(default=False)
    location = models.CharField(max_length=255, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.username} ({self.role})"
    
    class Meta:
        db_table = 'users'


class BuyerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='buyer_profile')
    delivery_addresses = models.JSONField(default=list)
    order_count = models.IntegerField(default=0)


class SellerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='seller_profile')
    store_name = models.CharField(max_length=100)
    store_description = models.TextField(blank=True)
    store_logo = models.ImageField(upload_to='stores/', null=True, blank=True)
    store_banner = models.ImageField(upload_to='stores/banners/', null=True, blank=True)
    address = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, default=0)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, default=0)
    is_active = models.BooleanField(default=True)
    opening_hours = models.JSONField(default=dict)
    rating = models.FloatField(default=0)
    total_orders = models.IntegerField(default=0)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=1500)
    is_approved = models.BooleanField(default=False)
    
    def __str__(self):
        return self.store_name


class DriverProfile(models.Model):
    VEHICLE_CHOICES = (
        ('motorcycle', 'Motorcycle'),
        ('bicycle', 'Bicycle'),
        ('car', 'Car'),
    )
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='driver_profile')
    vehicle_type = models.CharField(max_length=50, choices=VEHICLE_CHOICES, default='motorcycle')
    vehicle_plate = models.CharField(max_length=20, blank=True)
    vehicle_image = models.ImageField(upload_to='vehicles/', null=True, blank=True)
    license_image = models.ImageField(upload_to='licenses/', null=True, blank=True)
    is_available = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)
    rating = models.FloatField(default=0)
    total_deliveries = models.IntegerField(default=0)
    bank_details = models.JSONField(default=dict)
    
    def __str__(self):
        return f"{self.user.username} - {self.vehicle_type}"