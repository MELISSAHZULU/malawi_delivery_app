from rest_framework import serializers
from decimal import Decimal
from .models import DriverLocation, DeliveryAssignment, DriverActivityLog
from accounts.models import DriverProfile, User
from orders.models import Order


class DriverLocationSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.username', read_only=True)
    driver_phone = serializers.CharField(source='driver.phone_number', read_only=True)
    vehicle_type = serializers.CharField(source='driver.vehicle_type', read_only=True)
    rating = serializers.FloatField(source='driver.rating', read_only=True)
    
    class Meta:
        model = DriverLocation
        fields = [
            'id', 'driver', 'driver_name', 'driver_phone', 'vehicle_type', 
            'rating', 'latitude', 'longitude', 'is_online', 'last_updated'
        ]
        read_only_fields = ['driver', 'last_updated']


class DeliveryAssignmentSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.username', read_only=True, allow_null=True)
    driver_phone = serializers.CharField(source='driver.phone_number', read_only=True, allow_null=True)
    driver_rating = serializers.FloatField(source='driver.rating', read_only=True, allow_null=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    customer_name = serializers.CharField(source='order.buyer.username', read_only=True)
    customer_phone = serializers.CharField(source='order.buyer.phone_number', read_only=True, allow_null=True)
    delivery_address = serializers.CharField(source='order.delivery_address', read_only=True)
    delivery_instructions = serializers.CharField(source='order.delivery_instructions', read_only=True)
    seller_name = serializers.CharField(source='order.seller.store_name', read_only=True)
    seller_address = serializers.CharField(source='order.seller.address', read_only=True)
    seller_phone = serializers.CharField(source='order.seller.user.phone_number', read_only=True, allow_null=True)
    total_amount = serializers.DecimalField(source='order.total', max_digits=10, decimal_places=2, read_only=True)
    delivery_fee = serializers.DecimalField(source='order.delivery_fee', max_digits=10, decimal_places=2, read_only=True)
    items = serializers.SerializerMethodField()
    
    class Meta:
        model = DeliveryAssignment
        fields = [
            'id', 'order', 'order_number', 'driver', 'driver_name', 'driver_phone', 
            'driver_rating', 'status', 'assigned_at', 'accepted_at', 'picked_up_at', 
            'delivered_at', 'customer_name', 'customer_phone', 'delivery_address',
            'delivery_instructions', 'seller_name', 'seller_address', 'seller_phone',
            'total_amount', 'delivery_fee', 'items', 'distance_to_restaurant', 'distance_to_customer'
        ]
        read_only_fields = ['assigned_at']
    
    def get_items(self, obj):
        try:
            items_data = obj.order.items if hasattr(obj.order, 'items') else []
            if isinstance(items_data, list):
                return items_data
            return []
        except:
            return []


class DriverActivityLogSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.user.username', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True, allow_null=True)
    
    class Meta:
        model = DriverActivityLog
        fields = [
            'id', 'driver', 'driver_name', 'action', 'timestamp', 
            'order', 'order_number', 'latitude', 'longitude', 'notes'
        ]
        read_only_fields = ['timestamp']


class AvailableOrderSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    order_number = serializers.CharField()
    seller_name = serializers.CharField()
    seller_address = serializers.CharField()
    seller_latitude = serializers.DecimalField(max_digits=9, decimal_places=6, allow_null=True)
    seller_longitude = serializers.DecimalField(max_digits=9, decimal_places=6, allow_null=True)
    total = serializers.DecimalField(max_digits=10, decimal_places=2)
    delivery_fee = serializers.DecimalField(max_digits=10, decimal_places=2)
    items_count = serializers.IntegerField()
    distance = serializers.FloatField(allow_null=True)
    pickup_location = serializers.DictField(allow_null=True)
