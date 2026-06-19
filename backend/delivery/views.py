from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import DriverLocation, DeliveryAssignment
from .serializers import DriverLocationSerializer, DeliveryAssignmentSerializer
from orders.models import Order
from accounts.models import DriverProfile
from notifications.models import Notification
import random

User = get_user_model()

class DriverLocationView(generics.RetrieveUpdateAPIView):
    """Update driver's current location"""
    permission_classes = [IsAuthenticated]
    serializer_class = DriverLocationSerializer
    
    def get_object(self):
        location, created = DriverLocation.objects.get_or_create(
            driver=self.request.user
        )
        return location

class AvailableDriversView(APIView):
    """Get list of available drivers"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        available_drivers = DriverProfile.objects.filter(
            is_available=True,
            is_verified=True,
            user__is_active=True
        )
        
        drivers_data = []
        for driver in available_drivers:
            location = DriverLocation.objects.filter(driver=driver.user).first()
            drivers_data.append({
                'id': driver.id,
                'user_id': driver.user.id,
                'username': driver.user.username,
                'phone_number': driver.user.phone_number,
                'vehicle_type': driver.vehicle_type,
                'vehicle_plate': driver.vehicle_plate,
                'rating': driver.rating,
                'location': {
                    'latitude': float(location.latitude) if location else 0,
                    'longitude': float(location.longitude) if location else 0,
                } if location else None
            })
        
        return Response(drivers_data)

class AssignDriverView(APIView):
    """Assign a specific driver to an order"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        order_id = request.data.get('order_id')
        driver_id = request.data.get('driver_id')
        
        if not order_id or not driver_id:
            return Response(
                {'error': 'Order ID and Driver ID required'},
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
        
        # Get driver
        try:
            driver_user = User.objects.get(id=driver_id, role='driver')
            driver_profile = DriverProfile.objects.get(user=driver_user)
        except (User.DoesNotExist, DriverProfile.DoesNotExist):
            return Response(
                {'error': 'Driver not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if driver is available
        if not driver_profile.is_available:
            return Response(
                {'error': 'Driver is not available'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create delivery assignment
        assignment = DeliveryAssignment.objects.create(
            order=order,
            driver=driver_user,
            status='accepted'
        )
        
        # Update order
        order.driver = driver_user
        order.status = 'picked_up'
        order.save()
        
        # Notify driver
        Notification.objects.create(
            user=driver_user,
            title=f"New Delivery: {order.order_number}",
            message=f"You have been assigned to deliver order {order.order_number}. Pickup from {order.seller.store_name}.",
            type='delivery',
            data={
                'order_id': order.id,
                'order_number': order.order_number,
                'pickup_address': order.seller.address,
                'dropoff_address': order.delivery_address,
                'total': float(order.total)
            }
        )
        
        # Notify seller
        Notification.objects.create(
            user=order.seller.user,
            title=f"Driver Assigned: {order.order_number}",
            message=f"Driver {driver_user.username} has been assigned to deliver order {order.order_number}.",
            type='delivery',
            data={
                'order_id': order.id,
                'order_number': order.order_number,
                'driver_name': driver_user.username,
                'driver_phone': driver_user.phone_number,
                'vehicle_type': driver_profile.vehicle_type,
                'vehicle_plate': driver_profile.vehicle_plate
            }
        )
        
        # Notify buyer
        Notification.objects.create(
            user=order.buyer.user,
            title=f"Driver Assigned: {order.order_number}",
            message=f"Your order {order.order_number} is being delivered by {driver_user.username}.",
            type='delivery',
            data={
                'order_id': order.id,
                'order_number': order.order_number,
                'driver_name': driver_user.username,
                'driver_phone': driver_user.phone_number,
                'vehicle_type': driver_profile.vehicle_type,
                'vehicle_plate': driver_profile.vehicle_plate
            }
        )
        
        return Response({
            'success': True,
            'assignment': DeliveryAssignmentSerializer(assignment).data,
            'message': 'Driver assigned successfully'
        }, status=status.HTTP_200_OK)

class AutoAssignDriverView(APIView):
    """Auto-assign the best available driver"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        order_id = request.data.get('order_id')
        
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
        
        # Get available drivers
        available_drivers = DriverProfile.objects.filter(
            is_available=True,
            is_verified=True,
            user__is_active=True
        )
        
        if not available_drivers.exists():
            return Response(
                {'error': 'No drivers available'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Select a random available driver
        driver_profile = random.choice(available_drivers)
        driver_user = driver_profile.user
        
        # Create delivery assignment
        assignment = DeliveryAssignment.objects.create(
            order=order,
            driver=driver_user,
            status='accepted'
        )
        
        # Update order
        order.driver = driver_user
        order.status = 'picked_up'
        order.save()
        
        # Notify driver
        Notification.objects.create(
            user=driver_user,
            title=f"New Delivery: {order.order_number}",
            message=f"You have been assigned to deliver order {order.order_number}. Pickup from {order.seller.store_name}.",
            type='delivery',
            data={
                'order_id': order.id,
                'order_number': order.order_number,
                'pickup_address': order.seller.address,
                'dropoff_address': order.delivery_address,
                'total': float(order.total)
            }
        )
        
        # Notify seller
        Notification.objects.create(
            user=order.seller.user,
            title=f"Driver Assigned: {order.order_number}",
            message=f"Driver {driver_user.username} has been assigned to deliver order {order.order_number}.",
            type='delivery',
            data={
                'order_id': order.id,
                'order_number': order.order_number,
                'driver_name': driver_user.username,
                'driver_phone': driver_user.phone_number,
                'vehicle_type': driver_profile.vehicle_type,
                'vehicle_plate': driver_profile.vehicle_plate
            }
        )
        
        # Notify buyer
        Notification.objects.create(
            user=order.buyer.user,
            title=f"Driver Assigned: {order.order_number}",
            message=f"Your order {order.order_number} is being delivered by {driver_user.username}.",
            type='delivery',
            data={
                'order_id': order.id,
                'order_number': order.order_number,
                'driver_name': driver_user.username,
                'driver_phone': driver_user.phone_number,
                'vehicle_type': driver_profile.vehicle_type,
                'vehicle_plate': driver_profile.vehicle_plate
            }
        )
        
        return Response({
            'success': True,
            'driver': {
                'id': driver_user.id,
                'username': driver_user.username,
                'phone_number': driver_user.phone_number,
                'vehicle_type': driver_profile.vehicle_type,
                'vehicle_plate': driver_profile.vehicle_plate,
                'rating': driver_profile.rating,
            },
            'assignment': DeliveryAssignmentSerializer(assignment).data,
            'message': 'Driver assigned successfully'
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
        action = request.data.get('action')  # 'pick_up', 'deliver'
        
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
            assignment.save()
            
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
            
            return Response({'success': True, 'status': 'driving'})
            
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
            
            return Response({'success': True, 'status': 'delivered'})
            
        else:
            return Response(
                {'error': f'Invalid action: {action}'},
                status=status.HTTP_400_BAD_REQUEST
            )
