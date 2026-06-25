from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.db.models import Q
from geopy.distance import geodesic
import json
from decimal import Decimal

from .models import DriverLocation, DeliveryAssignment, DriverActivityLog
from .serializers import (
    DriverLocationSerializer, 
    DeliveryAssignmentSerializer,
    DriverActivityLogSerializer
)
from orders.models import Order
from accounts.models import DriverProfile
from notifications.models import Notification
from orders.serializers import OrderSerializer

User = get_user_model()


def calculate_eta(lat1, lon1, lat2, lon2):
    """Calculate ETA in minutes based on distance and average speed"""
    try:
        if not lat1 or not lon1 or not lat2 or not lon2:
            return "Calculating..."
        
        distance = geodesic((lat1, lon1), (lat2, lon2)).km
        # Average speed in Malawi: 30 km/h in city
        speed = 30  # km/h
        time_minutes = (distance / speed) * 60
        
        if time_minutes < 1:
            return "1 min"
        elif time_minutes < 60:
            return f"{int(time_minutes)} min"
        else:
            hours = int(time_minutes / 60)
            mins = int(time_minutes % 60)
            return f"{hours}h {mins}m"
    except:
        return "Calculating..."


class DriverLocationView(generics.RetrieveUpdateAPIView):
    """Update driver's current location"""
    permission_classes = [IsAuthenticated]
    serializer_class = DriverLocationSerializer
    
    def get_object(self):
        location, created = DriverLocation.objects.get_or_create(
            driver=self.request.user
        )
        return location
    
    def update(self, request, *args, **kwargs):
        """Update location with additional logic"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        
        # Update location
        self.perform_update(serializer)
        
        # Log activity
        DriverActivityLog.objects.create(
            driver=request.user,
            action='online' if serializer.validated_data.get('is_active', True) else 'offline',
            latitude=serializer.validated_data.get('latitude'),
            longitude=serializer.validated_data.get('longitude')
        )
        
        # Check if driver has active delivery
        active_assignment = DeliveryAssignment.objects.filter(
            driver=request.user,
            status__in=['picked_up', 'driving']
        ).first()
        
        if active_assignment:
            # Calculate ETA to customer
            eta = calculate_eta(
                float(serializer.validated_data.get('latitude', 0)),
                float(serializer.validated_data.get('longitude', 0)),
                float(active_assignment.order.delivery_latitude) if active_assignment.order.delivery_latitude else None,
                float(active_assignment.order.delivery_longitude) if active_assignment.order.delivery_longitude else None
            )
            
            # Broadcast to customer via WebSocket
            try:
                from .consumers import notify_customer
                notify_customer(active_assignment.order.buyer.user.id, {
                    'type': 'driver_location',
                    'latitude': float(serializer.validated_data.get('latitude', 0)),
                    'longitude': float(serializer.validated_data.get('longitude', 0)),
                    'eta': eta,
                    'driver_name': request.user.username,
                    'driver_phone': request.user.phone_number,
                })
            except:
                pass
        
        return Response({
            'success': True,
            'message': 'Location updated successfully',
            'data': serializer.data
        })


class AvailableDriversView(APIView):
    """Get list of available drivers with their locations"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        # Get online drivers
        online_drivers = DriverLocation.objects.filter(is_active=True)
        
        drivers_data = []
        for location in online_drivers:
            try:
                profile = DriverProfile.objects.get(user=location.driver)
                drivers_data.append({
                    'id': profile.id,
                    'user_id': location.driver.id,
                    'username': location.driver.username,
                    'phone_number': location.driver.phone_number,
                    'vehicle_type': profile.vehicle_type,
                    'vehicle_plate': profile.vehicle_plate,
                    'rating': float(profile.rating) if profile.rating else 0,
                    'location': {
                        'latitude': float(location.latitude),
                        'longitude': float(location.longitude),
                    },
                    'last_updated': location.last_updated.isoformat()
                })
            except DriverProfile.DoesNotExist:
                continue
        
        return Response(drivers_data)


class AcceptDeliveryView(APIView):
    """Driver accepts a delivery order (First Come First Serve)"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        order_id = kwargs.get('order_id')
        
        if not order_id:
            return Response(
                {'error': 'Order ID required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get order
        try:
            order = Order.objects.get(id=order_id)
        except Order.DoesNotExist:
            return Response(
                {'error': 'Order not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if order is ready
        if order.status != 'ready':
            return Response(
                {'error': 'Order is not ready for pickup'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if driver is available
        driver = request.user
        try:
            driver_profile = DriverProfile.objects.get(user=driver)
        except DriverProfile.DoesNotExist:
            return Response(
                {'error': 'Driver profile not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        if not driver_profile.is_available:
            return Response(
                {'error': 'Driver is not available'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if driver has active deliveries (max 2 like UberEats)
        active_count = DeliveryAssignment.objects.filter(
            driver=driver,
            status__in=['pending', 'accepted', 'picked_up', 'driving']
        ).count()
        
        if active_count >= 2:
            return Response({
                'error': f'You already have {active_count} active deliveries. Complete them first.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Calculate distance to restaurant
        distance_to_restaurant = None
        driver_location = DriverLocation.objects.filter(driver=driver, is_active=True).first()
        if driver_location and order.seller_latitude and order.seller_longitude:
            try:
                distance_to_restaurant = geodesic(
                    (float(driver_location.latitude), float(driver_location.longitude)),
                    (float(order.seller_latitude), float(order.seller_longitude))
                ).km
            except:
                pass
        
        # Create delivery assignment
        assignment = DeliveryAssignment.objects.create(
            order=order,
            driver=driver,
            status='accepted',
            distance_to_restaurant=round(distance_to_restaurant, 2) if distance_to_restaurant else None
        )
        
        # Update order
        order.driver = driver
        order.status = 'confirmed'
        order.save()
        
        # Log activity
        DriverActivityLog.objects.create(
            driver=driver,
            action='accept',
            order=order
        )
        
        # Notify seller
        Notification.objects.create(
            user=order.seller.user,
            title=f"Driver Assigned: {order.order_number}",
            message=f"Driver {driver.username} has been assigned to deliver order {order.order_number}.",
            type='delivery',
            data={
                'order_id': order.id,
                'order_number': order.order_number,
                'driver_name': driver.username,
                'driver_phone': driver.phone_number,
                'vehicle_type': driver_profile.vehicle_type,
                'vehicle_plate': driver_profile.vehicle_plate
            }
        )
        
        # Notify buyer via WebSocket
        try:
            from .consumers import notify_customer
            notify_customer(order.buyer.user.id, {
                'type': 'driver_assigned',
                'driver_name': driver.username,
                'driver_phone': driver.phone_number,
                'vehicle': driver_profile.vehicle_type,
                'eta': calculate_eta(
                    float(driver_location.latitude) if driver_location else None,
                    float(driver_location.longitude) if driver_location else None,
                    float(order.seller_latitude) if order.seller_latitude else None,
                    float(order.seller_longitude) if order.seller_longitude else None
                )
            })
        except:
            pass
        
        return Response({
            'success': True,
            'assignment': DeliveryAssignmentSerializer(assignment).data,
            'message': 'Delivery accepted successfully'
        }, status=status.HTTP_200_OK)


class DriverOrdersView(generics.ListAPIView):
    """Get orders assigned to the current driver"""
    permission_classes = [IsAuthenticated]
    serializer_class = DeliveryAssignmentSerializer
    
    def get_queryset(self):
        return DeliveryAssignment.objects.filter(
            driver=self.request.user
        ).order_by('-assigned_at')


class UpdateDeliveryStatusView(APIView):
    """Update delivery status (picked_up, delivered, etc.)"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        order_id = kwargs.get('order_id')
        action = request.data.get('action')  # 'pick_up', 'deliver', 'driving'
        
        if not action:
            return Response(
                {'error': 'Action required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            assignment = DeliveryAssignment.objects.get(
                order_id=order_id,
                driver=request.user
            )
        except DeliveryAssignment.DoesNotExist:
            return Response(
                {'error': 'Delivery assignment not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        order = assignment.order
        
        if action == 'pick_up':
            if order.status != 'picked_up':
                return Response(
                    {'error': 'Order not ready for pickup'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            order.status = 'driving'
            order.save()
            assignment.status = 'driving'
            assignment.picked_up_at = timezone.now()
            
            # Calculate distance to customer
            if order.delivery_latitude and order.delivery_longitude:
                driver_location = DriverLocation.objects.filter(driver=request.user).first()
                if driver_location:
                    try:
                        distance = geodesic(
                            (float(driver_location.latitude), float(driver_location.longitude)),
                            (float(order.delivery_latitude), float(order.delivery_longitude))
                        ).km
                        assignment.distance_to_customer = round(distance, 2)
                    except:
                        pass
            
            assignment.save()
            
            # Log activity
            DriverActivityLog.objects.create(
                driver=request.user,
                action='pickup',
                order=order
            )
            
            # Notify buyer
            Notification.objects.create(
                user=order.buyer.user,
                title=f"Order on the Way: {order.order_number}",
                message=f"Your order {order.order_number} is on the way! Driver: {request.user.username}.",
                type='delivery',
                data={'order_id': order.id, 'order_number': order.order_number}
            )
            
            # Notify seller
            Notification.objects.create(
                user=order.seller.user,
                title=f"Order Picked Up: {order.order_number}",
                message=f"Order {order.order_number} has been picked up by {request.user.username}.",
                type='delivery',
                data={'order_id': order.id, 'order_number': order.order_number}
            )
            
            # Notify buyer via WebSocket
            try:
                from .consumers import notify_customer
                notify_customer(order.buyer.user.id, {
                    'type': 'status_update',
                    'status': 'driving',
                    'order_id': order.id
                })
            except:
                pass
            
            return Response({
                'success': True, 
                'status': 'driving',
                'assignment': DeliveryAssignmentSerializer(assignment).data
            })
            
        elif action == 'deliver':
            if order.status != 'driving':
                return Response(
                    {'error': 'Order not on the way'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            order.status = 'delivered'
            order.actual_delivery_time = timezone.now()
            order.save()
            assignment.status = 'delivered'
            assignment.delivered_at = timezone.now()
            assignment.save()
            
            # Log activity
            DriverActivityLog.objects.create(
                driver=request.user,
                action='deliver',
                order=order
            )
            
            # Notify buyer
            Notification.objects.create(
                user=order.buyer.user,
                title=f"Order Delivered: {order.order_number}",
                message=f"Your order {order.order_number} has been delivered successfully! 🎉",
                type='delivery',
                data={'order_id': order.id, 'order_number': order.order_number}
            )
            
            # Notify seller
            Notification.objects.create(
                user=order.seller.user,
                title=f"Order Delivered: {order.order_number}",
                message=f"Order {order.order_number} has been delivered successfully.",
                type='delivery',
                data={'order_id': order.id, 'order_number': order.order_number}
            )
            
            # Notify buyer via WebSocket
            try:
                from .consumers import notify_customer
                notify_customer(order.buyer.user.id, {
                    'type': 'status_update',
                    'status': 'delivered',
                    'order_id': order.id
                })
            except:
                pass
            
            return Response({
                'success': True, 
                'status': 'delivered',
                'assignment': DeliveryAssignmentSerializer(assignment).data
            })
            
        elif action == 'driving':
            # Just update status to driving
            order.status = 'driving'
            order.save()
            assignment.status = 'driving'
            assignment.save()
            
            return Response({
                'success': True,
                'status': 'driving'
            })
            
        else:
            return Response(
                {'error': f'Invalid action: {action}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class AvailableOrdersForDriverView(APIView):
    """
    Get available orders for drivers.
    Returns orders that are 'ready' and have no driver assigned.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        # Check if user is a driver
        if request.user.role != 'driver':
            return Response(
                {'error': 'Only drivers can view available orders'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get driver's current location
        driver_location = DriverLocation.objects.filter(
            driver=request.user, 
            is_active=True
        ).first()
        
        # Get orders that are ready and have no driver assigned
        orders = Order.objects.filter(
            status='ready',
            driver__isnull=True
        ).select_related('seller').order_by('-created_at')
        
        result = []
        for order in orders:
            # Calculate distance from driver to restaurant
            distance = None
            if driver_location and order.seller_latitude and order.seller_longitude:
                try:
                    distance = geodesic(
                        (float(driver_location.latitude), float(driver_location.longitude)),
                        (float(order.seller_latitude), float(order.seller_longitude))
                    ).km
                except:
                    pass
            
            # Get items count
            items_count = len(order.items) if order.items else 0
            
            result.append({
                'id': order.id,
                'order_number': order.order_number,
                'seller_name': order.seller.store_name if hasattr(order.seller, 'store_name') else 'Store',
                'seller_address': order.seller.address if hasattr(order.seller, 'address') else '',
                'seller_latitude': float(order.seller_latitude) if order.seller_latitude else None,
                'seller_longitude': float(order.seller_longitude) if order.seller_longitude else None,
                'total': float(order.total),
                'delivery_fee': float(order.delivery_fee) if order.delivery_fee else 1500,
                'items_count': items_count,
                'distance': round(distance, 2) if distance else None,
                'pickup_location': {
                    'lat': float(order.seller_latitude) if order.seller_latitude else 0,
                    'lng': float(order.seller_longitude) if order.seller_longitude else 0
                } if order.seller_latitude else None
            })
        
        # Sort by distance (closest first)
        result.sort(key=lambda x: x['distance'] if x['distance'] is not None else 999999)
        
        return Response(result)


class NearbyDriversView(APIView):
    """Get nearby drivers for a given location"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        latitude = request.query_params.get('latitude')
        longitude = request.query_params.get('longitude')
        radius = request.query_params.get('radius', 10)  # km
        
        if not latitude or not longitude:
            return Response(
                {'error': 'Latitude and longitude required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        online_drivers = DriverLocation.objects.filter(is_active=True)
        
        nearby = []
        for driver_loc in online_drivers:
            try:
                distance = geodesic(
                    (float(latitude), float(longitude)),
                    (float(driver_loc.latitude), float(driver_loc.longitude))
                ).km
                
                if distance <= float(radius):
                    nearby.append({
                        'driver_id': driver_loc.driver.id,
                        'driver_name': driver_loc.driver.username,
                        'phone': driver_loc.driver.phone_number,
                        'distance': round(distance, 2),
                        'latitude': float(driver_loc.latitude),
                        'longitude': float(driver_loc.longitude),
                    })
            except:
                continue
        
        # Sort by distance
        nearby.sort(key=lambda x: x['distance'])
        
        return Response(nearby)