f# orders/models.py

from django.db import models
from accounts.models import User, BuyerProfile, SellerProfile, DriverProfile
from marketplace.models import Product

class Order(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('preparing', 'Preparing'),
        ('ready', 'Ready for Pickup'),
        ('picked_up', 'Picked Up'),
        ('driving', 'Driving'),
        ('arrived', 'Arrived'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
    )
    
    buyer = models.ForeignKey(BuyerProfile, on_delete=models.CASCADE, related_name='orders')
    seller = models.ForeignKey(SellerProfile, on_delete=models.CASCADE, related_name='orders')
    driver = models.ForeignKey(DriverProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name='orders')
    
    order_number = models.CharField(max_length=20, unique=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    items = models.JSONField()  # List of {product_id, name, quantity, price, total}
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    
    delivery_address = models.CharField(max_length=255)
    delivery_latitude = models.DecimalField(max_digits=9, decimal_places=6)
    delivery_longitude = models.DecimalField(max_digits=9, decimal_places=6)
    
    payment_method = models.CharField(max_length=20, default='paychangu')
    payment_status = models.CharField(max_length=20, default='pending')
    payment_transaction_id = models.CharField(max_length=100, null=True, blank=True)
    
    tracking_updates = models.JSONField(default=list)  # List of {status, timestamp, location}
    
    estimated_delivery_time = models.DateTimeField(null=True, blank=True)
    actual_delivery_time = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Order #{self.order_number} - {self.buyer.user.username}"
    
    def save(self, *args, **kwargs):
        if not self.order_number:
            import random
            self.order_number = f"MW{str(random.randint(1000, 9999))}{str(random.randint(100, 999))}"
        super().save(*args, **kwargs)

class OrderTracking(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='tracking')
    status = models.CharField(max_length=20, choices=Order.STATUS_CHOICES)
    location = models.JSONField(default=dict)  # {"lat": 0, "lng": 0}
    note = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.order.order_number} - {self.status} at {self.created_at}"