from rest_framework import serializers
from .models import DriverLocation, DeliveryAssignment
from orders.serializers import OrderSerializer

class DriverLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverLocation
        fields = ['latitude', 'longitude', 'is_active', 'last_updated']

class DeliveryAssignmentSerializer(serializers.ModelSerializer):
    order_details = OrderSerializer(source='order', read_only=True)
    driver_name = serializers.CharField(source='driver.username', read_only=True)
    
    class Meta:
        model = DeliveryAssignment
        fields = [
            'id', 'order', 'order_details', 'driver', 'driver_name',
            'status', 'assigned_at', 'accepted_at', 'picked_up_at',
            'delivered_at', 'notes'
        ]
        read_only_fields = ['assigned_at', 'accepted_at', 'picked_up_at', 'delivered_at']