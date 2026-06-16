from rest_framework import serializers
from .models import Order, OrderTracking

class OrderTrackingSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderTracking
        fields = '__all__'

class OrderSerializer(serializers.ModelSerializer):
    buyer_name = serializers.CharField(source='buyer.user.username', read_only=True)
    seller_name = serializers.CharField(source='seller.store_name', read_only=True)
    driver_name = serializers.CharField(source='driver.user.username', read_only=True)
    driver_phone = serializers.CharField(source='driver.user.phone_number', read_only=True)
    tracking = OrderTrackingSerializer(many=True, read_only=True)
    
    class Meta:
        model = Order
        fields = ('id', 'order_number', 'buyer', 'buyer_name', 'seller', 'seller_name',
                 'driver', 'driver_name', 'driver_phone', 'status', 'items', 
                 'subtotal', 'delivery_fee', 'total', 'delivery_address',
                 'delivery_latitude', 'delivery_longitude', 'payment_method',
                 'payment_status', 'payment_transaction_id', 'tracking',
                 'estimated_delivery_time', 'actual_delivery_time',
                 'is_offline', 'created_at', 'updated_at')
        read_only_fields = ('created_at', 'updated_at', 'order_number')

class OrderCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ('seller', 'items', 'delivery_address', 'delivery_latitude',
                 'delivery_longitude', 'payment_method')