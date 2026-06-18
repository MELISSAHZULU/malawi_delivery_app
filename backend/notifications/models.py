from django.db import models
from django.conf import settings
from django.utils import timezone

class Notification(models.Model):
    NOTIFICATION_TYPES = (
        ('order', 'Order Update'),
        ('payment', 'Payment Update'),
        ('delivery', 'Delivery Update'),
        ('system', 'System Notification'),
        ('promotion', 'Promotion'),
    )
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=100)
    message = models.TextField()
    type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES, default='system')
    is_read = models.BooleanField(default=False)
    data = models.JSONField(default=dict)  # Additional data like order_id, payment_id, etc.
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.title}"
    
    def mark_as_read(self):
        self.is_read = True
        self.save()
    
    @classmethod
    def create_order_notification(cls, user, order, action):
        """Create notification for order updates"""
        return cls.objects.create(
            user=user,
            title=f"Order {action}: {order.order_number}",
            message=f"Your order {order.order_number} has been {action}.",
            type='order',
            data={'order_id': order.id, 'order_number': order.order_number}
        )
    
    @classmethod
    def create_payment_notification(cls, user, payment, action):
        """Create notification for payment updates"""
        return cls.objects.create(
            user=user,
            title=f"Payment {action}: {payment.transaction_id}",
            message=f"Your payment of MWK {payment.amount} has been {action}.",
            type='payment',
            data={'payment_id': payment.id, 'transaction_id': payment.transaction_id}
        )
    
    @classmethod
    def create_system_notification(cls, user, title, message, data=None):
        """Create system notification"""
        return cls.objects.create(
            user=user,
            title=title,
            message=message,
            type='system',
            data=data or {}
        )
