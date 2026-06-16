# orders/views.py

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import Order, OrderTracking
from .serializers import OrderSerializer, OrderTrackingSerializer
from payments.services import PayChanguService

class CreateOrderView(generics.CreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderSerializer
    
    def perform_create(self, serializer):
        order = serializer.save(buyer=self.request.user.buyer_profile)
        # Create initial tracking
        OrderTracking.objects.create(
            order=order,
            status='pending',
            note='Order placed successfully'
        )
        
        # Initiate payment with PayChangu
        paychangu = PayChanguService()
        payment_url = paychangu.initiate_payment(
            order=order,
            mobile_number=self.request.data.get('mobile_number'),
            operator=self.request.data.get('operator')
        )
        
        return order, payment_url
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order, payment_url = self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response({
            'order': OrderSerializer(order).data,
            'payment_url': payment_url
        }, status=status.HTTP_201_CREATED, headers=headers)

class OrderTrackView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    
    def get(self, request, *args, **kwargs):
        order = self.get_object()
        # Check if user has permission (buyer, seller, or driver)
        user = request.user
        if (user.role == 'buyer' and order.buyer.user != user) or \
           (user.role == 'seller' and order.seller.user != user) or \
           (user.role == 'driver' and order.driver.user != user):
            return Response({'error': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
        
        return super().get(request, *args, **kwargs)

class UpdateOrderStatusView(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    
    def update(self, request, *args, **kwargs):
        order = self.get_object()
        new_status = request.data.get('status')
        
        # Validate status transition
        allowed_transitions = {
            'pending': ['confirmed', 'cancelled'],
            'confirmed': ['preparing', 'cancelled'],
            'preparing': ['ready', 'cancelled'],
            'ready': ['picked_up', 'cancelled'],
            'picked_up': ['driving'],
            'driving': ['arrived'],
            'arrived': ['delivered'],
        }
        
        if new_status not in allowed_transitions.get(order.status, []):
            return Response({'error': f'Invalid status transition from {order.status} to {new_status}'},
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Update order
        order.status = new_status
        order.save()
        
        # Create tracking entry
        OrderTracking.objects.create(
            order=order,
            status=new_status,
            location=request.data.get('location', {}),
            note=request.data.get('note', '')
        )
        
        # Send real-time update via WebSocket
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'order_{order.id}',
            {
                'type': 'order_update',
                'data': {
                    'order_id': order.id,
                    'status': new_status,
                    'timestamp': str(order.updated_at)
                }
            }
        )
        
        return Response({
            'order': OrderSerializer(order).data,
            'message': f'Order status updated to {new_status}'
        })