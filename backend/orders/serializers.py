from rest_framework import serializers
from .models import Order, OrderTracking
from marketplace.serializers import ProductSerializer

class OrderTrackingSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderTracking
        fields = ['id', 'status', 'location', 'note', 'created_at']

class OrderSerializer(serializers.ModelSerializer):
    tracking = OrderTrackingSerializer(many=True, read_only=True)
    buyer_name = serializers.CharField(source='buyer.user.username', read_only=True)
    seller_name = serializers.CharField(source='seller.store_name', read_only=True)
    driver_name = serializers.CharField(source='driver.username', read_only=True, allow_null=True)
    driver_phone = serializers.CharField(source='driver.phone_number', read_only=True, allow_null=True)
    
    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'status', 'items', 'subtotal',
            'delivery_fee', 'total', 'delivery_address', 'delivery_latitude',
            'delivery_longitude', 'payment_method', 'payment_status',
            'payment_transaction_id', 'tracking_updates', 'tracking',
            'estimated_delivery_time', 'actual_delivery_time',
            'buyer', 'buyer_name', 'seller', 'seller_name',
            'driver', 'driver_name', 'driver_phone', 'created_at', 'updated_at'
        ]
        read_only_fields = ['order_number', 'tracking_updates', 'created_at', 'updated_at']

class OrderCreateSerializer(serializers.Serializer):
    items = serializers.ListField(
        child=serializers.DictField()
    )
    delivery_address = serializers.CharField(max_length=255)
    delivery_latitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False)
    delivery_longitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False)
    payment_method = serializers.CharField(default='paychangu')
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2)
    delivery_fee = serializers.DecimalField(max_digits=10, decimal_places=2, default=1500)
    total = serializers.DecimalField(max_digits=10, decimal_places=2)
