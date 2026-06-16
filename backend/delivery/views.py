from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from .models import DriverLocation, DeliveryAssignment
from .serializers import DriverLocationSerializer, DeliveryAssignmentSerializer
from orders.models import Order
from django.utils import timezone

class DriverLocationView(generics.RetrieveUpdateAPIView):
    """Update driver's current location"""
    permission_classes = [IsAuthenticated]
    serializer_class = DriverLocationSerializer
    
    def get_object(self):
        location, created = DriverLocation.objects.get_or_create(
            driver=self.request.user
        )
        return location

class DriverOrdersView(generics.ListAPIView):
    """Get orders assigned to the current driver"""
    permission_classes = [IsAuthenticated]
    serializer_class = DeliveryAssignmentSerializer
    
    def get_queryset(self):
        return DeliveryAssignment.objects.filter(
            driver=self.request.user
        ).order_by('-assigned_at')

class AcceptDeliveryView(generics.UpdateAPIView):
    """Accept a delivery assignment"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        order_id = kwargs.get('order_id')
        order = get_object_or_404(Order, id=order_id)
        
        # Check if order is available
        if order.status != 'ready':
            return Response(
                {'error': 'Order is not ready for pickup'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if driver is available
        if not request.user.driver_profile.is_available:
            return Response(
                {'error': 'Driver is not available'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create delivery assignment
        assignment = DeliveryAssignment.objects.create(
            order=order,
            driver=request.user,
            status='accepted'
        )
        assignment.accept()
        
        serializer = DeliveryAssignmentSerializer(assignment)
        return Response(serializer.data, status=status.HTTP_200_OK)

class UpdateDeliveryStatusView(generics.UpdateAPIView):
    """Update delivery status"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        order_id = kwargs.get('order_id')
        status_action = request.data.get('action')
        
        try:
            assignment = DeliveryAssignment.objects.get(
                order_id=order_id,
                driver=request.user
            )
        except DeliveryAssignment.DoesNotExist:
            return Response(
                {'error': 'Assignment not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        valid_actions = ['pick_up', 'start_driving', 'deliver']
        if status_action not in valid_actions:
            return Response(
                {'error': f'Invalid action. Must be one of: {valid_actions}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if status_action == 'pick_up':
            if assignment.status != 'accepted':
                return Response({'error': 'Order not accepted yet'}, status=400)
            assignment.pick_up()
        
        elif status_action == 'start_driving':
            if assignment.status != 'picked_up':
                return Response({'error': 'Order not picked up yet'}, status=400)
            assignment.start_driving()
        
        elif status_action == 'deliver':
            if assignment.status != 'driving':
                return Response({'error': 'Not driving yet'}, status=400)
            assignment.deliver()
        
        serializer = DeliveryAssignmentSerializer(assignment)
        return Response(serializer.data)