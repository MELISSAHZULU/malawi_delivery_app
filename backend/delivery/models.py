from django.db import models
from django.conf import settings
from django.utils import timezone
from orders.models import Order


class DriverLocation(models.Model):
    """Track driver real-time location"""
    driver = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='driver_location',
        limit_choices_to={'role': 'driver'}
    )
    latitude = models.DecimalField(max_digits=10, decimal_places=7, default=0)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, default=0)
    is_active = models.BooleanField(default=True)
    last_updated = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.driver.username} - ({self.latitude}, {self.longitude})"
    
    class Meta:
        db_table = 'delivery_driver_locations'
        ordering = ['-last_updated']


class DeliveryAssignment(models.Model):
    """Track delivery assignments"""
    
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('picked_up', 'Picked Up'),
        ('driving', 'Driving'),
        ('arrived', 'Arrived'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
    )
    
    order = models.OneToOneField(
        Order, 
        on_delete=models.CASCADE, 
        related_name='delivery_assignment'
    )
    driver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='deliveries',
        limit_choices_to={'role': 'driver'}
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    assigned_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    picked_up_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)
    
    # Distance tracking (in km)
    distance_to_restaurant = models.FloatField(null=True, blank=True)
    distance_to_customer = models.FloatField(null=True, blank=True)
    
    def __str__(self):
        return f"Delivery {self.order.order_number} - {self.driver.username}"
    
    def accept(self):
        self.status = 'accepted'
        self.accepted_at = timezone.now()
        self.save()
        self.order.driver = self.driver
        self.order.status = 'confirmed'
        self.order.save()
    
    def pick_up(self):
        self.status = 'picked_up'
        self.picked_up_at = timezone.now()
        self.save()
        self.order.status = 'picked_up'
        self.order.save()
    
    def start_driving(self):
        self.status = 'driving'
        self.save()
        self.order.status = 'driving'
        self.order.save()
    
    def deliver(self):
        self.status = 'delivered'
        self.delivered_at = timezone.now()
        self.save()
        self.order.status = 'delivered'
        self.order.actual_delivery_time = timezone.now()
        self.order.save()
    
    class Meta:
        db_table = 'delivery_assignments'
        ordering = ['-assigned_at']


class DriverActivityLog(models.Model):
    """Track driver activity for analytics"""
    ACTION_CHOICES = (
        ('online', 'Online'),
        ('offline', 'Offline'),
        ('accept', 'Accepted Order'),
        ('pickup', 'Picked Up'),
        ('deliver', 'Delivered'),
        ('cancel', 'Cancelled'),
    )
    
    driver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='driver_activity_logs',
        limit_choices_to={'role': 'driver'}
    )
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    timestamp = models.DateTimeField(auto_now_add=True)
    order = models.ForeignKey(
        Order, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    notes = models.TextField(blank=True, default='')
    
    def __str__(self):
        return f"{self.driver.username} - {self.action} at {self.timestamp}"
    
    class Meta:
        db_table = 'delivery_activity_logs'
        ordering = ['-timestamp']