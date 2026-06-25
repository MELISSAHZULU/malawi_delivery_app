from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import DriverLocation, DeliveryAssignment, DriverActivityLog
from orders.serializers import OrderSerializer
from accounts.models import DriverProfile

User = get_user_model()


class DriverLocationSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.username', read_only=True)
    driver_phone = serializers.CharField(source='driver.phone_number', read_only=True)
    vehicle_type = serializers.SerializerMethodField()
    rating = serializers.SerializerMethodField()
    
    class Meta:
        model = DriverLocation
        fields = [
            'latitude', 'longitude', 'is_active', 'last_updated',
            'driver_name', 'driver_phone', 'vehicle_type', 'rating'
        ]
    
    def get_vehicle_type(self, obj):
        try:
            profile = DriverProfile.objects.get(user=obj.driver)
            return profile.vehicle_type
        except DriverProfile.DoesNotExist:
            return None
    
    def get_rating(self, obj):
        try:
            profile = DriverProfile.objects.get(user=obj.driver)
            return float(profile.rating) if profile.rating else 0
        except DriverProfile.DoesNotExist:
            return 0


class DeliveryAssignmentSerializer(serializers.ModelSerializer):
    order_details = OrderSerializer(source='order', read_only=True)
    driver_name = serializers.CharField(source='driver.username', read_only=True)
    driver_phone = serializers.CharField(source='driver.phone_number', read_only=True)
    customer_name = serializers.CharField(source='order.buyer.username', read_only=True)
    customer_phone = serializers.CharField(source='order.buyer.phone_number', read_only=True)
    seller_name = serializers.CharField(source='order.seller.store_name', read_only=True)
    delivery_address = serializers.CharField(source='order.delivery_address', read_only=True)
    delivery_instructions = serializers.CharField(source='order.delivery_instructions', read_only=True)
    
    class Meta:
        model = DeliveryAssignment
        fields = [
            'id', 'order', 'order_details', 'driver', 'driver_name', 'driver_phone',
            'customer_name', 'customer_phone', 'seller_name', 'delivery_address',
            'delivery_instructions', 'status', 'assigned_at', 'accepted_at', 
            'picked_up_at', 'delivered_at', 'notes', 'distance_to_restaurant',
            'distance_to_customer'
        ]
        read_only_fields = ['assigned_at', 'accepted_at', 'picked_up_at', 'delivered_at']


class DriverActivityLogSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.username', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True, allow_null=True)
    
    class Meta:
        model = DriverActivityLog
        fields = [
            'id', 'driver', 'driver_name', 'action', 'timestamp',
            'order', 'order_number', 'latitude', 'longitude', 'notes'
        ]
        read_only_fields = ['timestamp']


class AvailableOrderSerializer(serializers.Serializer):
    """Serializer for orders available for drivers"""
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