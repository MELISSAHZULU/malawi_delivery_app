from django.db import models
from django.utils import timezone
from orders.models import Order

class PaymentTransaction(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    )
    
    OPERATOR_CHOICES = (
        ('airtel', 'Airtel Money'),
        ('tnm', 'TNM Mpamba'),
    )
    
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='payments')
    transaction_id = models.CharField(max_length=100, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='MWK')
    
    paychangu_reference = models.CharField(max_length=100, null=True, blank=True)
    paychangu_status = models.CharField(max_length=50, default='pending')
    
    mobile_number = models.CharField(max_length=15)
    operator = models.CharField(max_length=10, choices=OPERATOR_CHOICES)
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    callback_data = models.JSONField(default=dict)
    
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Payment {self.transaction_id} - {self.status}"
    
    def mark_completed(self):
        self.status = 'completed'
        self.completed_at = timezone.now()
        self.save()
        self.order.payment_status = 'completed'
        self.order.save()
    
    def mark_failed(self, error_message=None):
        self.status = 'failed'
        if error_message:
            self.callback_data['error'] = error_message
        self.save()
        self.order.payment_status = 'failed'
        self.order.save()
