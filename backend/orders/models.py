from django.db import models
from django.conf import settings
from django.utils import timezone
from accounts.models import BuyerProfile, SellerProfile

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
    driver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='driver_orders',
        limit_choices_to={'role': 'driver'}
    )
    
    order_number = models.CharField(max_length=20, unique=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    items = models.JSONField()
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=1500)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Delivery address
    delivery_address = models.CharField(max_length=255)
    delivery_instructions = models.TextField(blank=True, default='')
    
    # Location coordinates
    delivery_latitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6, 
        null=True, 
        blank=True,
        help_text="Latitude of delivery address"
    )
    delivery_longitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6, 
        null=True, 
        blank=True,
        help_text="Longitude of delivery address"
    )
    seller_latitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6, 
        null=True, 
        blank=True,
        help_text="Latitude of seller/restaurant"
    )
    seller_longitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6, 
        null=True, 
        blank=True,
        help_text="Longitude of seller/restaurant"
    )
    
    payment_method = models.CharField(max_length=20, default='paychangu')
    payment_status = models.CharField(max_length=20, default='pending')
    payment_transaction_id = models.CharField(max_length=100, null=True, blank=True)
    
    tracking_updates = models.JSONField(default=list)
    estimated_delivery_time = models.DateTimeField(null=True, blank=True)
    actual_delivery_time = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Order #{self.order_number} - {self.buyer.user.username}"
    
    def save(self, *args, **kwargs):
        if not self.order_number:
            import random
            self.order_number = f"MW{random.randint(1000, 9999)}{random.randint(100, 999)}"
        super().save(*args, **kwargs)
    
    def add_tracking_update(self, status, location=None, note=None):
        update = {
            'status': status,
            'timestamp': timezone.now().isoformat(),
            'location': location or {},
            'note': note or ''
        }
        self.tracking_updates.append(update)
        self.status = status
        self.save()
        return update

class OrderTracking(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='tracking')
    status = models.CharField(max_length=20, choices=Order.STATUS_CHOICES)
    location = models.JSONField(default=dict)
    note = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.order.order_number} - {self.status} at {self.created_at}"