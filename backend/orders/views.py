from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .models import Order, OrderTracking
from .serializers import OrderSerializer, OrderCreateSerializer
from payments.services import PayChanguService

class CreateOrderView(generics.CreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderCreateSerializer
    
    def perform_create(self, serializer):
        buyer = self.request.user.buyer_profile
        
        # Calculate totals
        items = self.request.data.get('items', [])
        subtotal = sum(item.get('price', 0) * item.get('quantity', 1) for item in items)
        seller_id = self.request.data.get('seller')
        seller = SellerProfile.objects.get(id=seller_id)
        delivery_fee = seller.delivery_fee
        
        order = serializer.save(
            buyer=buyer,
            subtotal=subtotal,
            delivery_fee=delivery_fee,
            total=subtotal + delivery_fee
        )
        
        # Create initial tracking
        OrderTracking.objects.create(
            order=order,
            status='pending',
            note='Order placed successfully'
        )
        
        return order
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = self.perform_create(serializer)
        
        # Initiate payment
        paychangu = PayChanguService()
        payment_result = paychangu.initiate_payment(
            order=order,
            mobile_number=request.data.get('mobile_number'),
            operator=request.data.get('operator')
        )
        
        return Response({
            'order': OrderSerializer(order).data,
            'payment': payment_result
        }, status=status.HTTP_201_CREATED)

class OrderListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'buyer':
            return Order.objects.filter(buyer__user=user)
        elif user.role == 'seller':
            return Order.objects.filter(seller__user=user)
        elif user.role == 'driver':
            return Order.objects.filter(driver__user=user)
        return Order.objects.none()

class OrderDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Order.objects.all()
    serializer_class = OrderSerializer

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
            return Response({
                'error': f'Invalid status transition from {order.status} to {new_status}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        order.status = new_status
        order.save()
        
        # Create tracking entry
        OrderTracking.objects.create(
            order=order,
            status=new_status,
            location=request.data.get('location', {}),
            note=request.data.get('note', '')
        )
        
        # Send WebSocket update
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

class CancelOrderView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, order_id):
        try:
            order = Order.objects.get(id=order_id, buyer__user=request.user)
            if order.status in ['pending', 'confirmed', 'preparing']:
                order.status = 'cancelled'
                order.save()
                return Response({'message': 'Order cancelled successfully'})
            return Response({'error': 'Order cannot be cancelled'}, status=status.HTTP_400_BAD_REQUEST)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
        
# orders/views.py
class WeeklyEarningsView(APIView):
    def get(self, request):
        # Calculate earnings for last 7 days
        pass


# orders/views.py
class UpdateOrderStatusView(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderSerializer
    
    def get_queryset(self):
        return Order.objects.filter(seller__user=self.request.user)