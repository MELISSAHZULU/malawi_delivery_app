from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
from .models import Order, OrderTracking
from .serializers import OrderSerializer, OrderCreateSerializer, OrderTrackingSerializer
from accounts.models import BuyerProfile, SellerProfile

class OrderListView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return OrderCreateSerializer
        return OrderSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'buyer':
            return Order.objects.filter(buyer__user=user).order_by('-created_at')
        elif user.role == 'seller':
            return Order.objects.filter(seller__user=user).order_by('-created_at')
        elif user.role == 'driver':
            return Order.objects.filter(driver=user).order_by('-created_at')
        return Order.objects.none()
    
    def perform_create(self, serializer):
        buyer = BuyerProfile.objects.get(user=self.request.user)
        # Get seller from the first item
        # For now, use a default seller or get from request
        seller_id = self.request.data.get('seller_id')
        if seller_id:
            seller = SellerProfile.objects.get(id=seller_id)
        else:
            # Default seller (you should handle this properly)
            seller = SellerProfile.objects.first()
        
        serializer.save(
            buyer=buyer,
            seller=seller,
            order_number=f"MW-{timezone.now().strftime('%Y%m%d')}-{Order.objects.count() + 1}"
        )

class OrderDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'buyer':
            return Order.objects.filter(buyer__user=user)
        elif user.role == 'seller':
            return Order.objects.filter(seller__user=user)
        elif user.role == 'driver':
            return Order.objects.filter(driver=user)
        return Order.objects.none()

class OrderTrackingView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderTrackingSerializer
    
    def get_queryset(self):
        order_id = self.kwargs.get('order_id')
        return OrderTracking.objects.filter(order_id=order_id)

class UpdateOrderStatusView(generics.UpdateAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    
    def update(self, request, *args, **kwargs):
        order = self.get_object()
        new_status = request.data.get('status')
        location = request.data.get('location', {})
        note = request.data.get('note', '')
        
        if not new_status:
            return Response(
                {'error': 'Status is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update order status
        order.status = new_status
        order.save()
        
        # Create tracking entry
        OrderTracking.objects.create(
            order=order,
            status=new_status,
            location=location,
            note=note
        )
        
        return Response(OrderSerializer(order).data)
