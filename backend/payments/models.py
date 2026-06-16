# payments/models.py

from django.db import models
from orders.models import Order

class PaymentTransaction(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='payments')
    
    transaction_id = models.CharField(max_length=100, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='MWK')
    
    # PayChangu specific
    paychangu_reference = models.CharField(max_length=100, null=True, blank=True)
    paychangu_status = models.CharField(max_length=50, default='pending')
    
    mobile_number = models.CharField(max_length=15)
    operator = models.CharField(max_length=10)  # Airtel, TNM
    
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ], default='pending')
    
    callback_data = models.JSONField(default=dict)
    
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"Payment {self.transaction_id} - {self.status}"
